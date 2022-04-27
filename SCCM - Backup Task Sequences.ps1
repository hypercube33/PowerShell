<#
.DESCRIPTION
Exports all configuration manager task sequences without content/dependencies.

Author: Eswar Koneti
Version: 1.0
Date: 24/Jan/2020
#>

#Get the script start time
$starttime=get-date
Write-host "Script started at $starttime"

#import configuration manager powershell module
try {
    Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
}
    catch [System.Exception] {
    Write-Warning "Unable to load the Configuration Manager Powershell module from $env:SMS_ADMIN_UI_PATH" ; break
}

#get the sitecode
$SiteCode = Get-PSDrive -PSProvider CMSITE
Set-Location -Path "$($SiteCode.Name):\"

#get list of all task sequences
$ts = Get-CMTaskSequence  | select Name
foreach($name in $ts)
{
    #Replace any unsupported characters with empty space for folder name
    $tsname=$name.Name.replace(":","").replace(",","").replace("*","").replace("?","").replace("\","").replace("\","").replace("<","").replace(">","")

    #export the task sequences to share folder
    Write-Host "Exporting: $tsname"
    Export-CMTaskSequence -Name $name.name -WithDependence $true  -withContent $true -ExportFilePath ("E:\21\"+$tsname+ ".zip") -Force
}

#Get script end time
$endtime=Get-date
#Get the script execution time (total)
$Scripttime=($endtime-$starttime).Seconds
write-host "Script ended at $endtime with execution time of $Scripttime seconds"