Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
Import-Module ActiveDirectory
$CSVFile = "C:\ContosoTemp\CDW Results3.csv"
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
if ((Get-Module ConfigurationManager) -eq $null)
{
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
{
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

# ---------------------------------------------------------------------


$List = Import-CSV -Path $CSVFile

# Get all BIOS Information
$WMI = Get-WmiObject  -Namespace "root\sms\site_$($SiteCode)" -Class SMS_G_System_PC_BIOS -ComputerName $ProviderMachineName



$NewCSV = ForEach ($Entry in $List)
{
    #Read the CSV In
    $ComputerName = $Entry.'Machine Name'   
    $Mfg = $Entry.Manufacturer
    $ModelWMI = $Entry.Model
    $TPMVersion = $Entry.'TPM Version'
    $TPMActivated = $Entry.'TPM Activated'
    $TPMEnabled = $Entry.'TPM Enabled'

    # Query SCCM for Information
    $Device = Get-CMDevice -Name $ComputerName -Fast
    $ResourceID = $Device.ResourceID


    $BiosRow = $WMI | Where-Object {$_.ResourceID -eq $ResourceID}
    
    # Write out BIOS
    $Entry.BIOSVersion = $BiosRow.SMBIOSBIOSVersion
    
    # Write OS
    $Entry.OS = $Device.DeviceOS

    # Write out to new CSV
    $Entry
}

#$NewCSV | Out-GridView

$NewCSV | Export-CSV C:\ContosoTemp\TMP.csv -NoTypeInformation


