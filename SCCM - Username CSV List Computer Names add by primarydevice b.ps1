<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Imports a CSV File of Usernames and adds primarydevice from SCCM to it
#>
import-module activedirectory

$Groups = @("Group_OnBase_DistrictLeaders","Zone Leaders")

$SAMUsers = foreach ($Group in $Groups)
{
    Get-ADGroupMember -Identity $Group | Select SamAccountName
}




Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
Import-Module ActiveDirectory

$Domain = "Contoso"

# ---------------------------------------------------------------------
# Import SCCM Site 
# ---------------------------------------------------------------------
# Site configuration
$SiteCode = "CM1" # Site code 
$ProviderMachineName = "sccm.contoso.com" # SMS Provider machine name

# Customizations
$initParams = @{}

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

# ---------------------------------------------------------------------


$NewCSV = ForEach ($User in $SAMUsers)
{

    $sAMAccountName = $User.SamAccountName
    # Get User Device Affinity
    $Computer =  Get-CMUserDeviceAffinity -UserName "$($Domain)\$($sAMAccountName)" | Select-Object -ExpandProperty ResourceName

    $Computer
}

$NewCSV | Out-File C:\ContosoTemp\INC0166786.txt