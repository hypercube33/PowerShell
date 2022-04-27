<#
Brian Thorp
November 2019

This is the proof of concept script to on-the-fly generate an xml to update office to a target of our choice.
The intended use is to allow it to read what is installed (Office 365) and selectively add components and keep the same:
    Bitlevel
    Version of Office
    Blocked features in-tact so we're not adding unwanted parts and pieces
    Settings
#>
###########################
# What do we want to do? 
    # Add or Install something
    # Do we care about a specific version, or just use whatever is there on existing office products?
# Look at what we need on the existing install
# Build an XML file
# Install Office
###########################
# 
$DisplayLevel = "Full"
$SharedComputer = "0"
$DeviceLicensing = "0"
$TargetVersion = "16.0.13127.21624" # MUST have 16.0. preceeding to work properly

# This is what we want to have at the end of the install.
# For example if you're adding project, just have "Project"
# $TargetProduct = "Office","Visio","Project"
$TargetProduct = "Office", "Project", "Visio"

# $OfficeToInstall = $True
# $VisioToInstall = $True
# $ProjectToInstall = $False

# Where do we want to output the XML file for O365 Setup.exe to use?
$OutputXML = "C:\ContosoTemp\O365.xml"

###########################
# Look up what office is installed, version etc.
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
function Get-O365Channel
{
    #https://docs.microsoft.com/en-us/configmgr/sum/deploy-use/manage-office-365-proplus-updates#change-the-update-channel-after-you-enable-office-365-clients-to-receive-updates-from-configuration-manager

    $ChannelPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration\"
    $ChannelProperty = "CDNBaseUrl"

    if (Test-Path $ChannelPath)
    {
        $CurrentChannelURL = (Get-ItemProperty -Path $ChannelPath -Name $ChannelProperty).$ChannelProperty
        Switch ($CurrentChannelURL)
        {
            # Beta | Monthly
            # "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"    {$Channel = "Monthly"}
            "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"    {$Channel = "Current Channel"}

            # Stable (Enterprise)
            # "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"    {$Channel = "Semi-Annual Channel"}
            "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"    {$Channel = "Semi-Annual Enterprise Channel"}

            # Stable Beta
            # "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be"    {$Channel = "Monthly Channel (Targeted)"}
            "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be"    {$Channel = "Current Channel (Preview)"}

            # Release-Ahead Stable (AKA Consumer Stable)
            # "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf"    {$Channel = "Semi-Annual Channel (Targeted)"}
            "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf"    {$Channel = "Semi-Annual Enterprise Channel (Preview)"}

            # New Enterprise Channels 2020+
            "http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6"    {$Channel = "Monthly Enterprise Channel"}

            "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"    {$Channel = "Current Channel"}

            "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be"     {$Channel = "Current Channel (Preview)"}

            "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"     {$Channel = "Semi-Annual Enterprise Channel"}

            "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf"    {$Channel = "Semi-Annual Enterprise Channel (Preview)"}

            "http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f"    {$Channel = "Beta Channel"}
        }
        return $Channel
    }
}
function Get-O365Arch
{
    $ArchPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration\"
    $ArchProperty = "Platform"

    if (Test-Path $ArchPath)
    {
        $RegArch = (Get-ItemProperty -Path $ArchPath -Name $ArchProperty).$ArchProperty
        Switch ($RegArch)
        {
            "x64"    {$Arch = "64"}
            "x86"    {$Arch = "32"}
        }
        return $Arch
    }
}

# Is access installed?
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
###########################
$Office             = Get-ARP_O365 -DisplayName "Microsoft Office 365 ProPlus*"
$Visio              = Get-ARP_O365 -DisplayName "Microsoft Visio Professional*"
$Project            = Get-ARP_O365 -DisplayName "Microsoft Project Professional*"
$Access             = Get-O365Access
$CurrentChannel     = Get-O365Channel
$OfficeArch         = Get-O365Arch

if ($Null -ne $office)
{
    $OfficeInstalled    = $Office[0]
    $OfficeBitLevel     = $Office[1]
    $OfficeName         = $Office[2]
    $OfficeVersion      = [version]$Office[3]

    # Office 365 Semi-Annual Enterprise Channels
    if ($OfficeVersion.Build -eq  "9126") { $OfficeChannel = "1803" }
    if ($OfficeVersion.Build -eq "10730") { $OfficeChannel = "1808" }
    if ($OfficeVersion.Build -eq "11328") { $OfficeChannel = "1902" }
    if ($OfficeVersion.Build -eq "11929") { $OfficeChannel = "1908" }
    if ($OfficeVersion.Build -eq "12527") { $OfficeChannel = "2002" }
    if ($OfficeVersion.Build -eq "13127") { $OfficeChannel = "2008" }

    if ($Access) {$AccessExclude = $False}
    # If office isnt installed, skip
    if (!($OfficeInstalled))  {$OfficeToInstall = $False}   

    # If Office is installed make sure the version isnt newer than what we are aiming for
    if ($OfficeInstalled)
    {
        # Is the target version newer?
        # Installed Version Greater Than Target Version? 1808 > 2008
        if (($OfficeVersion.build) -gt ([version]$TargetVersion).build) {Exit-Script -ErrorCode "99999"}
        if (($OfficeVersion.build) -lt ([version]$TargetVersion).build) {$OfficeToInstall = $True}
    }
}

if ($null -ne $visio)
{
    $VisioInstalled    = $Visio[0]
    $VisioBitLevel     = $Visio[1]
    $VisioName         = $Visio[2]
    $VisioVersion      = [version]$Visio[3]

    if (!($VisioInstalled))  {$VisioToInstall = $False}

    # If Visio is installed make sure the version isnt newer than what we are aiming for
    if ($VisioInstalled -eq $true)
    {
        if (($VisioVersion.build) -gt ([version]$TargetVersion).build) {Exit-Script -ErrorCode "99999"}
        if (($VisioVersion.build) -lt ([version]$TargetVersion).build) {$VisioToInstall = $True}
    }
    
}

if ($null -ne $Project)
{
    $ProjectInstalled    = $Project[0]
    $ProjectBitLevel     = $Project[1]
    $ProjectName         = $Project[2]
    $ProjectVersion      = [version]$Project[3]

    # If Project isnt installed dont try to install it
    if (!($ProjectInstalled))  {$ProjectToInstall = $False}

    # If Project is installed make sure the version isnt newer than what we are aiming for
    if ($ProjectInstalled)
    {
        if (($ProjectVersion.build) -gt ([version]$TargetVersion).build) {Exit-Script -ErrorCode "99999"}
        if (($ProjectVersion.build) -lt ([version]$TargetVersion).build) {$VisioToInstall = $True}
    }
    
}
##########################
# Flip above if we are targeting a product to install and its not currently installed
foreach ($Product in $TargetProduct)
{
    if ($Product -eq "Office")
    {
        $OfficeToInstall = $True
    }
    if ($Product -eq "Visio")
    {
        $VisioToInstall = $True
    }
    if ($Product -eq "Project")
    {
        $ProjectToInstall = $True
    }
}
##########################
# XML File Generation
##########################
if ($Null -ne ($OfficeToInstall -or $VisioToInstall -or $ProjectToInstall))
{
    # https://docs.microsoft.com/en-us/DeployOffice/update-channels-changes#office-deployment-tool
    switch ($CurrentChannel)
    {
        # 2020+
        "Monthly Enterprise Channel"                    { $XMLChannel = "MonthlyEnterprise" }
        "Current Channel"                               { $XMLChannel = "Current" }
        "Current Channel (Preview)"                     { $XMLChannel = "CurrentPreview" }
        "Semi-Annual Enterprise Channel"                { $XMLChannel = "SemiAnnual" }
        "Semi-Annual Enterprise Channel (Preview)"      { $XMLChannel = "SemiAnnualPreview" }
        "Beta Channel"                                  { $XMLChannel = "BetaChannel" }
    }

if ($AccessExclude -eq $False)
{
    $OfficeXML = `
@'
<Product ID="O365ProPlusRetail">
    <Language ID="MatchOS" />
    <ExcludeApp ID="Groove" />
    <ExcludeApp ID="Lync" />
    <ExcludeApp ID="OneDrive" />
    <ExcludeApp ID="Teams" />
    <ExcludeApp ID="Access" />
</Product>
'@
}
if ($AccessExclude -eq $True)
{
    $OfficeXML = `
@'
<Product ID="O365ProPlusRetail">
    <Language ID="MatchOS" />
    <ExcludeApp ID="Groove" />
    <ExcludeApp ID="Lync" />
    <ExcludeApp ID="OneDrive" />
    <ExcludeApp ID="Teams" />
    <ExcludeApp ID="Access" />
</Product>
'@
}

$VisioXML = `
@"
<Product ID="VisioProRetail">
</Product>
"@

$ProjectXML = `
@"
<Product ID="ProjectProRetail">
</Product>
"@

$Products = $Null
if ($OfficeToInstall) { $Products += $OfficeXML  }
if ($VisioToInstall)  { $Products += $VisioXML   }
if ($ProjectToInstall){ $Products += $ProjectXML }

$SetupXML = `
@"
<Configuration ID="8b4673a6-1461-4525-a5d9-3e366c4e2541">
<Add OfficeClientEdition="$OfficeArch" Channel="$XMLChannel" OfficeMgmtCOM="TRUE" Version="$TargetVersion">
    $Products
</Add>
<Property Name="SharedComputerLicensing" Value="$SharedComputer" />
<Property Name="PinIconsToTaskbar" Value="TRUE" />
<Property Name="SCLCacheOverride" Value="0" />
<Property Name="AUTOACTIVATE" Value="0" />
<Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
<Property Name="DeviceBasedLicensing" Value="$DeviceLicensing" />
<Display Level="$DisplayLevel" AcceptEULA="TRUE" />
</Configuration>
"@

    $SetupXML | Out-File $OutputXML
}