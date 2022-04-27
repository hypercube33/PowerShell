<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Imports a CSV File of User's DisplayNames, Looks them up in AD -> Username, and adds primarydevice from SCCM to it
#>
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


$List = Import-CSV -Path "UserList.csv"





$NewCSV = ForEach ($Entry in $List)
{
    #write-host $Entry
    $UserDisplayName = $Entry.'User Name'

    $UserDisplayName = $UserDisplayName -Replace '\s', "*"
    
    # Input Firstname Lastname and output sAMAccountname
    $sAMAccountname = (Get-ADUser -Filter { Name -like $UserDisplayName }).samaccountname

    # Get User Device Affinity
    $Entry.'Primary Computer Name' =  Get-CMUserDeviceAffinity -UserName "$($Domain)\$($sAMAccountName)" | Select-Object -ExpandProperty ResourceName

    $Entry
}

$NewCSV | Export-CSV C:\Contoso\tstusrs2.csv -NoTypeInformation