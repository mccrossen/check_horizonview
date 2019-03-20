<#

.SYNOPSIS
	Horizon View Local Check (Check MK Check)

.DESCRIPTION
	This script calls the prepared Horizon View Check in plugins directory.

.NOTES
	Name:        Horizon View Check for Check MK
	Version:     1.0
	Author:      Marcel Debray
	URL:		 https://github.com/mccrossen/checkmk_horizonview
	Date:        20/03/2019

#>

cd "C:\Program Files (x86)\check_mk\plugins\checkmk_horizonview"

$ConnectionServer = "horizonview.example.com"
$UserName = "monitoring"
$UserDomain = "example.com"
$Password = "password"
$count_hvlicenses = 100

$warn_lic = 0.80 * $count_hvlicenses
$err_lic = 0.95 * $count_hvlicenses

.\check_horizonview_agent_unreachable.ps1 -ConnectionServer $ConnectionServer  -UserName $UserName -UserDomain $UserDomain -Password $Password
.\check_horizonview_provisioning_error.ps1 -ConnectionServer $ConnectionServer  -UserName $UserName -UserDomain $UserDomain -Password $Password
.\check_horizonview_sessions.ps1 -ConnectionServer $ConnectionServer  -UserName $UserName -UserDomain $UserDomain -Password $Password -WarningSessionCount $warn_lic -CriticalSessionCoun $err_lic -MaxUsers $count_hvlicenses
.\check_horizonview_disabled_pools.ps1 -ConnectionServer $ConnectionServer  -UserName $UserName -UserDomain $UserDomain -Password $Password