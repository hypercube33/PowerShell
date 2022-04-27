<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   SCCM Detection Rule Script
   Checks through every user's HKCU path and validates that every single one is set properly.
   Designed to be used with a PSAD application to set all users' registry keys identical during OSD etc.
#>
#=== Can probably write a function to copy and paste from deploy-application array~~ BT
$regkeys = `
@(
    # New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\ThemeManager"; Name="DllName"; Value='%SystemRoot%\resources\themes\Aero\Aero.msstyles'}
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\ThemeManager"; Name="DllName"; Value='C:\Windows\resources\themes\Aero\Aero.msstyles'}
    New-Object PSObject -Property @{Path="Software\Policies\Microsoft\Internet Explorer\Main"; Name="DisableFirstRunCustomize"; Value="1"}
    New-Object PSObject -Property @{Path="SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SystemPaneSuggestionsEnabled"; Value="0"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.Windows.Cortana_cw5n1h2txyewy!CortanaUI"; Name="Enabled"; Value="0"}
    New-Object PSObject -Property @{Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.SkyDrive.Desktop"; Name="Enabled"; Value="0"}
    New-Object PSObject -Property @{Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance"; Name="Enabled"; Value="0"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\Windows Security Health\State"; Name="AccountProtection_MicrosoftAccount_Disconnected"; Value="0"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\Search"; Name="SearchboxTaskbarMode"; Value="0"}
    New-Object PSObject -Property @{Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"; Name="PeopleBand"; Value="0"}
    New-Object PSObject -Property @{Path="SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SystemPaneSuggestionsEnabled"; Value="0"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\Explorer\Ribbon"; Name="MinimizedStateTabletModeOff"; Value="0"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="LaunchTo"; Value="1"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="HideFileExt"; Value="0"}
    New-Object PSObject -Property @{Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name="OneDriveSetup"; Value="C:\Windows\SysWOW64\OneDriveSetup.exe /thfirstsetup"}
    New-Object PSObject -Property @{Path="Control Panel\Keyboard"; Name="InitialKeyboardIndicators"; Value="2"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Office\16.0\Outlook\Preferences"; Name="PinMail"; Value="2"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Office\16.0\Outlook\Options\Spelling"; Name="Check"; Value="1"}
    New-Object PSObject -Property @{Path="Control Panel\Desktop"; Name="LogPixels"; Value="96"}
    New-Object PSObject -Property @{Path="Control Panel\Desktop"; Name="Win8DpiScaling"; Value="1"}

    # 3.1 - O365 Add Outlook to Mobile
    New-Object PSObject -Property @{Path="Software\Microsoft\Office\16.0\Outlook\Options\General\"; Name="DisableOutlookMobileHyperlink"; Value="1"}
    New-Object PSObject -Property @{Path="Software\Policies\Microsoft\Office\16.0\Outlook\Options\General\"; Name="DisableOutlookMobileHyperlink"; Value="1"}

    # 4.0 - Bing/Cortana Search
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\Search"; Name="BingSearchEnabled"; Value="0"}
    New-Object PSObject -Property @{Path="Software\Microsoft\Windows\CurrentVersion\Search"; Name="CortanaConsent"; Value="0"}
)
# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'

# Excluded, Built-In Profiles
# Local System | NT Authority | NT Authority
$SystemProfiles = 'S-1-5-18', 'S-1-5-19', 'S-1-5-20'

# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = gp 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} | Where-Object {$_.SID -notin $SystemProfiles} |
    Select-Object   @{name="SID";expression={$_.PSChildName}}, 
                    @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                    @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}

# Add Default Hive
#$ProfileList += New-Object PSObject -Property @{SID="S-1-5-21-Default-User"; UserHive="C:\Users\Default\NTUSER.DAT";Username="Default"}
$ProfileDefault = New-Object PSObject
$ProfileDefault | Add-Member -MemberType NoteProperty -Name "SID" -Value "S-1-5-21-Default-User"
$ProfileDefault | Add-Member -MemberType NoteProperty -Name "UserHive" -Value "C:\Users\Default\NTUSER.DAT"
$ProfileDefault | Add-Member -MemberType NoteProperty -Name "UserName" -Value "Default"

$ProfileList = [array]$ProfileList + $ProfileDefault
 
# Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
$LoadedHives = Get-ChildItem Registry::HKEY_USERS | ? {$_.PSChildname -match $PatternSID} | Select-Object @{name="SID";expression={$_.PSChildName}}

# Get all users that are not currently logged or loaded into ram
$UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name="SID";expression={$_.InputObject}}, UserHive, Username

if (!(Test-Path HKU:))
{
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
}

# Loop through each profile on the machine
$results = Foreach ($item in $ProfileList) 
{
    # Load User ntuser.dat if it's not already loaded
    IF ($item.SID -in $UnloadedHives.SID)
    {
        #Load the registry into the HKU structure
        reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
    }
   
    foreach ($regkey in $regkeys)
    {
        $KeyPath = $RegKey.Path
        $KeyName = $RegKey.Name
        $KeyValue = $RegKey.Value

        # Test known good reg keys
        $regpath = "HKU:\$($Item.SID)\$KeyPath"

        if (Test-Path $RegPath)
        {
            #Write-Host $RegPath Exists

            # https://stackoverflow.com/questions/31547104/how-to-get-the-value-of-the-path-environment-variable-without-expanding-tokens
            # Dealing with Reg Expand Strings
            #  $regkey = get-item -Path $RegPath
            #  $PresentValue = $regkey.GetValue($KeyName, $null, 'DoNotExpandEnvironmentNames')

            $PresentValue = (Get-ItemProperty -path $regpath)

            # Compare registry value -> array
            $checkresult = ($PresentValue."$KeyName" -eq $keyvalue)
        }
        else
        {
            $checkresult = $false
        }

        # Results for test ->
        New-Object PSObject -Property @{CheckResult=$checkresult; Key=$keyname; User="$($Item.UserName)"; ExpectedResult=$keyvalue; Result=$($PresentValue."$KeyName")}
    }

    # Whole kees we needed deleted, too
    # $deletedreg = 'Software\Microsoft\Office\16.0\Outlook\Resiliency\DisabledItems'
    # !(Test-Path "HKU:\$SID\$deletedreg")

    # $deletedreg2 = 'SOFTWARE\Microsoft\Office\1x.0\Outlook\Resiliency\CrashingAddinList'
    # !(Test-Path "HKU:\$SID\$deletedreg2")


    #####################################################################
 
    # Unload ntuser.dat        
    IF ($item.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($Item.SID) | Out-Null
    }
}

if ($($results.CheckResult) -notcontains $False)
{
    Write-Host "Installed"
}