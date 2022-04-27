# https://social.technet.microsoft.com/Forums/Lync/en-US/983e7ec8-487c-41c2-b267-94ac50528eb4/source-path-of-all-the-applications?forum=configmanagersdk
Set-ExecutionPolicy Unrestricted -force
[System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.dll")) | Out-Null
[System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll")) | Out-Null
Import-Module -Name "$(split-path $Env:SMS_ADMIN_UI_PATH)\ConfigurationManager.psd1"
Set-Location CM1:
clear-host

function GetInfoApplications{
   
    foreach ($Application in Get-CMApplication) {
 
        $AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
        $AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title

        foreach ($DeploymentType in $AppMgmt.DeploymentType) {

            
            # Fill properties
            $AppData = @{            
                AppName            = $AppName
                Location           = $DeploymentType.Installer.Contents.Content.Location
                 }                           

            # Create object
            $Object = New-Object PSObject -Property $AppData
    
            # Return it
            $Object
        }
    }
 }

# Get the Data

$a = GetInfoApplications | select-object AppName, Location | Format-Table -AutoSize