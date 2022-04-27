# https://www.prajwaldesai.com/manage-sccm-duplicate-hardware-identifiers/

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
$USBMac = "3C:18:A0:07:90:24"
$SCCMFQDN = "sccm.contoso.com"

$MAC = Get-WMIObject -computerName “$SCCMFQDN” -Namespace root\sms\Site_CM1 -Class SMS_CommonMacAddresses # -Argument @{MACAddress=’00:11:22:33:44:55′}
$Mac.macaddress -match $USBMac

Set-WMIInstance -computerName "$SCCMFQDN" -Namespace root\sms\Site_CM1 -Class SMS_CommonMacAddresses -Argument @{MACAddress=$USBMac}