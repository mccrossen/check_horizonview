<#

.SYNOPSIS
	Horizon View Agent Provisioning Error Check (CheckMK Check)

.DESCRIPTION
	This script can be used with NRPE/NSClient++ to allow Nagios to monitor Horizon View for VMs in a 'provisioning_error' state.
	It will return warning when one machine is detected, critical when more than one machine is detected.

.EXAMPLE
	.\check_horizonview_provisioning_error.ps1 -SetPasswordFilePassword
	
	Save a password to a encrypted/hashed file (can be used later with the -PasswordFilePath switch)

.EXAMPLE
	.\check_horizonview_provisioning_error.ps1 -ConnectionServer horizonview.example.com -UserName monitor -Domain example.com -Password secret1
	
	Connect to Horizon View using a password

.EXAMPLE
	.\check_horizonview_provisioning_error.ps1 -ConnectionServer horizonview.example.com -UserName monitor -Domain example.com -PasswordFilePath c:\password.txt
	
	Connect to Horizon View using a password file

.NOTES
	Name:        Horizon View Agent Provisioning Error Check (Nagios Check)
	Version:     0.5
	Author:      Thomas Chubb
	Date:        26/10/2017

#>

param (
	[string]$ConnectionServer = 'horizonview.example.com',
	[string]$UserName = 'monitoring',
	[string]$UserDomain = 'example.com',
	[string]$PasswordFilePath = 'C:\Pass.txt',
	[string]$Password = $null,
	[switch]$SetPasswordFilePassword = $false
)

# Clear host
Clear-Host

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
	Write-Host '3 HVProblemVMsCount - UNKNOWN - Error loading the horizon view modules'
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
	Write-Host "3 HVProblemVMsCount - UNKNOWN - Error loading credentials using the $PasswordType"
	Exit 3
}

# Connect to horizon
try {
	Connect-HVServer -Server $ConnectionServer -Domain $UserDomain -Credential $Credentials -ErrorAction Stop | Out-Null
} catch {
	# UNKNOWN
	Write-Host "3 HVProblemVMsCount - UNKNOWN - Error connecting to $ConnectionServer"
	Exit 3
}

# Get session information
$ProblemVMs = (Get-HVMachineSummary).Base | where {$_.BasicState -eq 'PROVISIONING_ERROR'}

# Return nagios result
if ($ProblemVMs) {
	$ProblemVMsCount = 0
	$ProblemVMs | foreach {$ProblemVMsCount ++}
} else {
	# OK
	Write-Host "0 HVProblemVMsCount ProblemVMsCount=0 OK: VMs in a provisioning error state: 0"
	Exit 0
}

if ($ProblemVMsCount -gt 1) {
	# CRITICAL 
	Write-Host "2 HVProblemVMsCount ProblemVMsCount=$($ProblemVMsCount) CRITICAL: VMs in a provisioning error state: $($ProblemVMsCount)"
	Exit 2
} else {
	# WARNING
	Write-Host "1 HVProblemVMsCount ProblemVMsCount=$($ProblemVMsCount) WARNING: VMs in a provisioning error state: $($ProblemVMsCount)"
	Exit 1
}
