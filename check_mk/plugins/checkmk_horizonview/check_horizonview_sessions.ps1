<#
	
.SYNOPSIS
	Horizon View Sessions Check (CheckMK Check)

.DESCRIPTION
	This script can be used with Check MK Agent to allow Check MK to monitor Horizon View sessions.

.EXAMPLE
	.\check_horizonview_sessions.ps1 -SetPasswordFilePassword
	
	Save a password to a encrypted/hashed file (can be used later with the -PasswordFilePath switch)

.EXAMPLE
	.\check_horizonview_sessions.ps1 -ConnectionServer horizonview.example.com -UserName monitor -Domain example.com -Password secret1
	
	Connect to Horizon View using a password

.EXAMPLE
	.\check_horizonview_sessions.ps1 -ConnectionServer horizonview.example.com -UserName monitor -Domain example.com -PasswordFilePath c:\password.txt
	
	Connect to Horizon View using a password file
	
.EXAMPLE
	.\check_horizonview_sessions.ps1 -ConnectionServer horizonview.example.com -UserName monitor -Domain example.com -PasswordFilePath c:\password.txt -WarningSessionCount 80 -CriticalSessionCount 95 -MaxUsers 100
	
	Warn at 80 sessions, critical at 95 session and display out of 100 sessions.
	
.NOTES
	Name:        Horizon View Sessions Check (Chack MK Agent Check)
	Version:     1.0
	Author:      Thomas Chubb, Marcel debray
	URL:		 https://github.com/mccrossen/checkmk_horizonview
	Date:        20/03/2019

#>

param (
	[string]$ConnectionServer = 'horizonview.example.com',
	[string]$UserName = 'monitoring',
	[string]$UserDomain = 'example.com',
	[string]$PasswordFilePath = 'C:\Pass.txt',
	[string]$Password = $null,
	[int]$WarningSessionCount = 40,
	[int]$CriticalSessionCount = 47,
	[int]$MaxUsers = 50,
	[switch]$SetPasswordFilePassword = $false
)

# Run password file set wizard if the switch is used
if ($SetPasswordFilePassword) {
	Write-Host "Password file setup wizard (if the password file exists it will be overwritten)`n"
	$EnteredPasswordFilePath = Read-Host -Prompt 'Enter the path to the password file you wish to create/overwrite'
	$EnteredPassword = Read-Host -AsSecureString -Promp 'Enter the password to be saved in the password file (copy and paste is not supported)'
	try {
		$EnteredPassword | ConvertFrom-SecureString -ErrorAction Stop | Out-File $EnteredPasswordFilePath -Force -ErrorAction Stop
	} catch {
		Write-Host "`nError writing password file"
		Exit
	}
	Write-Host "`nPassword file saved ($EnteredPasswordFilePath)"
	Exit
}

# Load required modules
try {
	Import-Module VMware.VimAutomation.HorizonView -ErrorAction Stop
	Import-Module VMware.VimAutomation.Core -ErrorAction Stop
} catch {
	# UNKNOWN
	Write-Host '3 HVSessions - UNKNOWN: Error loading the horizon view modules'
	Exit 3
}

# Set credentials
if ($Password) {$PasswordType = 'password argument'} else {$PasswordType = 'password file argument'}
try {
	if ($Password) {
		# Use the plain text password argument
		$SecPassword = $Password | ConvertTo-SecureString -AsPlainText -Force
		$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,$SecPassword
		} else {
		# Use password the file if a plain text password argument is not provided
		$Password = Get-Content $PasswordFilePath -ErrorAction Stop
		$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,($Password | ConvertTo-SecureString -ErrorAction Stop) -ErrorAction Stop
	}
} catch {
	# UNKNOWN
	Write-Host "3 HVSessions - UNKNOWN: Error loading credentials using the $PasswordType"
	Exit 3
}

# Connect to horizon
try {
	Connect-HVServer -Server $ConnectionServer -Domain $UserDomain -Credential $Credentials -ErrorAction Stop | Out-Null
} catch {
	# UNKNOWN
	Write-Host "3 HVSessions - UNKNOWN: Error connecting to $ConnectionServer"
	Exit 3
}

# Get high level session information
$HVMachineSummary = Get-HVMachineSummary
$Sessions = $HVMachineSummary.Base

$TotalSessionCount = ($Sessions | where {$_.BasicState -eq 'CONNECTED' -or $_.BasicState -eq 'DISCONNECTED'} | Measure-Object).Count
$TotalConnectedSessionCount = ($Sessions | where {$_.BasicState -eq 'CONNECTED'} | Measure-Object).Count

# Format per pool stats and perfdata
$AllPools = (Get-HVPool).Base
$PoolStats = @() 
foreach ($Machine in $HVMachineSummary) {
	$Stat = New-Object -TypeName PSObject -Property @{
											'Pool' = ($Machine | Select -Expand NamesData).DesktopName
											'MachineState' = $Machine.Base.BasicState
	}
	$PoolStats += $Stat
}
# Pools with sessions
$PerfData = "TotalSessionCount=$TotalSessionCount|TotalConnectedSessionCount=$TotalConnectedSessionCount|"
$PoolsWithSessions = $PoolStats | where {$_.MachineState -eq 'CONNECTED' -or $_.MachineState -eq 'DISCONNECTED'} 
$PoolsWithSessions | Group Pool | Select Count,Name | foreach {
	$Perf = $_.Name + '=' + $_.Count + '|'
	$PerfData += $Perf
}
# Pools without sessions
if ($PoolsWithSessions) {
	$PoolsWithZeroSessionCount = Compare-Object $AllPools.Name $PoolsWithSessions.Pool | where {$_.SideIndicator -eq '<='}
	$PoolsWithZeroSessionCount | foreach {
		$Perf = $_.InputObject + '=0|'
		$PerfData += $Perf
	}
} else {
	$AllPools | foreach {
		$Perf = $_.Name + '=0|'
		$PerfData += $Perf
		}
}
$PerfData = ($PerfData.TrimEnd('|')).ToLower()

# Return nagios result
if ($TotalSessionCount -ge $CriticalSessionCount) {
	# CRITICAL
	Write-Host "2 HVSessions $PerfData CRITICAL: Total sessions: $TotalSessionCount/$MaxUsers ($TotalConnectedSessionCount Connected)"
	Exit 2
} elseif ($TotalSessionCount -ge $WarningSessionCount) {
	# WARNING
	Write-Host "1 HVSessions $PerfData WARNING: Total sessions: $TotalSessionCount/$MaxUsers ($TotalConnectedSessionCount Connected)"
	Exit 1
} else {
	# OK
	Write-Host "0 HVSessions $PerfData OK: Total sessions: $TotalSessionCount/$MaxUsers ($TotalConnectedSessionCount Connected)"
	Exit 0
}
