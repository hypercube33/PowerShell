<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Adds Microsoft Update from Update Server List
   Searches for Updates
   Downloads them if there are any
   Installs them if there are any
   Checks for reboot needed status
   Removes Microsoft Update from Update Server List
#>
# Register Microsoft Update as Source
$UpdateSvc = New-Object -ComObject Microsoft.Update.ServiceManager            
$UpdateSvc.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") | Out-Null

# Get all available Drivers
Write-Host 'Searching for updates...'
$Session = New-Object -ComObject Microsoft.Update.Session           
$Searcher = $Session.CreateUpdateSearcher() 

$Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'

<#
https://devblogs.microsoft.com/scripting/hey-scripting-guy-how-can-i-tell-which-software-updates-are-available-via-windows-update/
0   Default = Machine Only
1   Machine Only
#>
$Searcher.SearchScope =  1 # MachineOnly

<#
https://docs.microsoft.com/en-us/windows/win32/wua_sdk/searching--downloading--and-installing-updates
Server Selection
1   WSUS
2   Windows Update
3   Microsoft Update, Store, Other
#>
$Searcher.ServerSelection = 3 # Third Party
		
<#
Criteria
    Drivers
    Software

#>

$Criteria = "IsInstalled=0 and Type='Software'"
# Write-Host('Searching Driver-Updates...') -Fore Green     
$SearchResult = $Searcher.Search($Criteria)          
$Updates = $SearchResult.Updates
			
#Show available Drivers...
$Updates | Select-Object Title, DriverModel, DriverVerDate, Driverclass, DriverManufacturer # | Out-File "C:\ContosoTemp\driverupdates.txt"

Write-Host 'Downloading Updates...'

# Download Drivers
$UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
$updates | % { $UpdatesToDownload.Add($_) | out-null }
# Write-Host('Downloading Drivers...')  -Fore Green
$UpdateSession = New-Object -Com Microsoft.Update.Session
$Downloader = $UpdateSession.CreateUpdateDownloader()
$Downloader.Updates = $UpdatesToDownload
$Downloader.Download()

Write-Host 'Installing Updates...'

# Install Drivers
$UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
$updates | ForEach-Object { if ($_.IsDownloaded) { $UpdatesToInstall.Add($_) | out-null } }

# Write-Host('Installing Drivers...')  -Fore Green
$Installer = $UpdateSession.CreateUpdateInstaller()
$Installer.Updates = $UpdatesToInstall
$InstallationResult = $Installer.Install()

if($InstallationResult.RebootRequired) { $rebootRequired = $True } 
else { $rebootRequired = $False }

Write-Host 'Cleaning up...'

# Cleanup
$updateSvc.Services | Where-Object { $_.IsDefaultAUService -eq $false -and $_.ServiceID -eq "7971f918-a847-4430-9279-4a52d1efe18d" } | ForEach-Object { $UpdateSvc.RemoveService($_.ServiceID) }

# Report
if ($rebootRequired)
{
    Write-Host -ForegroundColor DarkYellow "Please Reboot"
}