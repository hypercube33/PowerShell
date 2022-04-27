<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   This takes a list of MAC addresses and adds them to SCCM's ignore list.
    Typically this is for things like USB dongles or docks used to image machines
    (OSD). Contains code from
   https://www.prajwaldesai.com/manage-sccm-duplicate-hardware-identifiers/
#>

##############################################################################>
# List your addresses here separated by commas
# $MACAddresses = "A", "B", "etc"
$MACAddresses = "A0:CE:C8:14:B2:79"

# =============================================================================
# Import Modules
# =============================================================================
# -----------------------------------------------------------------------------
# Active Directory
# -----------------------------------------------------------------------------
Import-Module ActiveDirectory -Cmdlet New-ADGroup, Add-ADGroupMember, Get-ADDomain

# -----------------------------------------------------------------------------
# SCCM (Requires Console Installed on machine)
# -----------------------------------------------------------------------------
Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction SilentlyContinue

# =============================================================================
# Connect to SCCM
# =============================================================================
# Grab the site server information
$SiteInfo                           = Get-PSDrive -PSProvider CmSite

# Site Code
$SiteCode                           = $SiteInfo.Name

# FQDN of Site Server
$SiteServer                         = $SiteInfo.Root

# =============================================================================
# Connect to AD
# =============================================================================
$DomainName = (Get-AdDomainController).Domain


# =============================================================================
# Add the MAC Addresses to the SCCM List
# =============================================================================
# Load the Common MAC Address Table
$MACTable = Get-CIMInstance -ComputerName $SiteServer -Namespace "root\sms\Site_$SiteCode" -Class "SMS_CommonMacAddresses"

foreach ($MACAddress in $MACAddresses)
{
    # Is it already in the list?
    $AlreadyExists = $MACAddress -eq ($MACTable.macaddress -Match $MACAddress)
    
    # Add it if we need to
    if (-not $AlreadyExists)
    {
        Write-Host "Adding $MACAddress"
        Set-CIMInstance -ComputerName $SiteServer -Namespace "root\sms\Site_$SiteCode" -Class "SMS_CommonMacAddresses" -Argument @{MACAddress=$MACAddress}
    }     
}