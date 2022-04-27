# =============================================================================
# Auto 365 Logic
# Version G2
# Brian Thorp
# =============================================================================
# TARGET Variables
$SharedComputer = "0" # 0 for False, 1 for True | Any = Use Existing or default to 0
$TargetVersion  = "1808"
$TargetChannel  = "Semi-Annual"
$TargetArch     = "32"


$TargetProduct  = "Visio"
$CurrentPatch   = "16.0.10730.20416"
# =============================================================================

# Detect if application is installed
# Returns the following:
#   True if Installed
#   Bit level of Office (THIS IS BROKEN AS OF 2021-06)
#   Product Name
#   Version Number
function Get-ARP_O365
{
    param(
        $DisplayName
    )

    # -----------------------------------------------------------------------------
    # Global Stuff
    # -----------------------------------------------------------------------------
    # PS App Deploy $is64bit
    [boolean]$Is64Bit = [boolean]((Get-WmiObject -Class 'Win32_Processor' -ErrorAction 'SilentlyContinue' | Where-Object { $_.DeviceID -eq 'CPU0' } | Select-Object -ExpandProperty 'AddressWidth') -eq 64)

    $path32 = "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $path64 = "\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

    # -----------------------------------------------------------------------------
    # Run regular code to check for install status
    # -----------------------------------------------------------------------------
    # Pre-Flight Null
    $Installed32 = $null
    $Installed64 = $null

    $Installed32 = Get-ChildItem HKLM:$path32 -Recurse -ErrorAction Stop | Get-ItemProperty -name DisplayName -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -like $DisplayName}
    if ($is64bit)
    {
        $Installed64 = Get-ChildItem HKLM:$path64 -Recurse -ErrorAction Stop | Get-ItemProperty -name DisplayName -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -like $DisplayName}
    }


    # If found in registry,
    if ($null -ne $Installed32)
    {
        $key = Get-ItemProperty -Path $Installed32.PSPath
        $DisplayName = $key.displayname
        $DisplayVersion = $key.displayversion
        return ($true,"32","$DisplayName","$Displayversion")
    }

    # If found in registry under 64bit path,
    if ($null -ne $installed64)
    {
        $key = Get-ItemProperty -Path $Installed32.PSPath
        $DisplayName = $key.displayname
        $DisplayVersion = $key.displayversion
        return ($true,"64","$DisplayName","$Displayversion")
    }
}


# Channel lookup
function Get-O365Channel
{
    #https://docs.microsoft.com/en-us/configmgr/sum/deploy-use/manage-office-365-proplus-updates#change-the-update-channel-after-you-enable-office-365-clients-to-receive-updates-from-configuration-manager

    $ChannelPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration\"
    $ChannelProperty = "CDNBaseUrl"

    if (Test-Path $ChannelPath)
    {
        $CurrentChannelURL = (Get-ItemProperty -Path $ChannelPath -Name $ChannelProperty).$ChannelProperty

        # https://docs.microsoft.com/en-us/mem/configmgr/sum/deploy-use/manage-office-365-proplus-updates#bkmk_channel
        Switch ($CurrentChannelURL)
        {
            # Beta
            # "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"    {$Channel = "Monthly"}

            # Stable (Enterprise)
            #"http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"    {$Channel = "Semi-Annual Channel"}

            # Stable Beta
            #"http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be"    {$Channel = "Monthly Channel (Targeted)"}

            # Release-Ahead Stable (AKA Consumer Stable)
            #"http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf"    {$Channel = "Semi-Annual Channel (Targeted)"}

            # ---- Updated 2020 -----
            # https://dannyda.com/2020/05/06/how-to-switch-change-between-monthly-channel-and-semi-annual-channel-for-office-365-office-2019-how-to-switch-update-channel-for-office-365-office-2019/

            # Beta Channel
            "http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f"    {$Channel = "Beta Channel"}

            # Current Channel (Preview)
            "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be"    {$Channel = "Current Channel (Preview)"}

            # Current Channel
            "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"    {$Channel = "Current Channel"}

            # Monthly Enterprise Channel
            "http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6"    {$Channel = "Monthly Enterprise Channel"}

            # Semi-Annual Enterprise Channel (Preview)
            "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf"    {$Channel = "Semi-Annual Enterprise Channel (Preview)"}

            # Semi-Annual Enterprise Channel
            "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"    {$Channel = "Semi-Annual Enterprise Channel"}
        }
        return $Channel
    }
}

# Determine if Access is installed on the system
function Get-O365Access
{
    $Path = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    $InstallProperty = "InstallationPath"
    
    if (Test-Path $Path)
    {
        $InstallationPath = (Get-ItemProperty -Path $Path -Name $InstallProperty).$InstallProperty
    }
        
    if (Test-Path $InstallationPath)
    {
        $AccessPath = "$InstallationPath\root\Office16\MSACCESS.EXE"
        if (Test-Path $AccessPath)
        {
            Return $True
        }
    }
}

# Was to be code to determine what files were staged in the package as cached - not used, or developed
function Get-StagedFileVersion
{
    $DirFiles = ""
    $Path = $DirFiles
}

# Examples for Office Products -- Determine if installed
$Office     = Get-ARP_O365 -DisplayName "Microsoft Office 365 ProPlus*"
$Visio      = Get-ARP_O365 -DisplayName "Microsoft Visio Professional*"
$Project    = Get-ARP_O365 -DisplayName "Microsoft Project Professional*"
$Access     = Get-O365Access



if ($Null -ne $office)
{
    $OfficeInstalled    = $Office[0]
    $OfficeBitLevel     = $Office[1]
    $OfficeName         = $Office[2]
    $OfficeVersion      = [version]$Office[3]

    if ($OfficeInstalled)
    {
        $OfficeUpdateChannel = Get-O365Channel
    }

    if ($OfficeVersion.Build -eq  "9126") { $OfficeChannel = "1803" }
    if ($OfficeVersion.Build -eq "10730") { $OfficeChannel = "1808" }
    if ($OfficeVersion.Build -eq "11328") { $OfficeChannel = "1902" }
}

if ($null -ne $visio)
{
    $VisioInstalled    = $Visio[0]
    $VisioBitLevel     = $Visio[1]
    $VisioName         = $Visio[2]
    $VisioVersion      = [version]$Visio[3]
}

if ($null -ne $Project)
{
    $ProjectInstalled    = $Project[0]
    $ProjectBitLevel     = $Project[1]
    $ProjectName         = $Project[2]
    $ProjectVersion      = [version]$Project[3]
}





#################################################################
Write-Host "Office is installed - $OfficeInstalled"
if ($OfficeChannel -eq $TargetVersion) { Write-Host "Office version $OfficeVersion matches target version of $TargetVersion" -ForegroundColor Green}

# Execute-Process -Path "$dirFiles\Setup.exe" -Parameters "/Configure C:\kworking\O365.xml"

Switch ($TargetProduct)
{
    "Visio"
    {
        # If O365 version doesnt match, we'll upgrade it or error out if its newer than our target
        if (!($OfficeChannel -lt $TargetVersion)) { Write-Host "Office version $OfficeVersion does not match target version of $TargetVersion" -ForegroundColor Red }
    }
}
