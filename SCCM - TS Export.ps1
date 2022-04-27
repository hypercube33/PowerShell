<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Exports a task sequence
#>
# Task Sequence to export:
$TaskSequenceName = "Windows 10 Enterprise"
$OutFilePath = "D:\Task Sequences\"

# -----------------------------------------------------------------------------
# Import Modules
# -----------------------------------------------------------------------------
# Active Directory
Import-Module ActiveDirectory -Cmdlet New-ADGroup, Add-ADGroupMember, Get-ADDomain

# SCCM
Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction SilentlyContinue

# -----------------------------------------------------------------------------
# Connect to SCCM
# -----------------------------------------------------------------------------
# Grab the site server information
$SiteInfo                           = Get-PSDrive -PSProvider CmSite

# Site Code
$SiteCode                           = $SiteInfo.Name

# FQDN of Site Server
$SiteServer                         = $SiteInfo.Root

# Change to the CM Location
[string]$SiteDir = $SiteCode + ":"
Set-Location $SiteDir




(Get-CMTaskSequence | Where-Object {$_.Name -eq "$TaskSequenceName"}).Sequence | Out-File "$OutFilePath\$TaskSequenceName.xml"