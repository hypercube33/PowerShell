<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Extended code from Modified code from Regin Ravi (?)
   Run the sections manually to output to a grid view
#>

clear-host
# =======================================================================
# DO NOT EDIT BELOW THIS LINE
# =======================================================================
cd C:
# SCCM
Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction SilentlyContinue

# Grab the site server information
$SiteInfo                           = Get-PSDrive -PSProvider CmSite

# Site Code
# $SiteCode                           = $SiteInfo.Name

# FQDN of Site Server
$SiteServer                         = $SiteInfo.Root

# Site configuration
$SiteCode = $SiteInfo.Name
$ProviderMachineName = $SiteServer



# Connect to the site's drive if it is not already present
if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue))
{
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
# =======================================================================
function GetInfoPackages()
{
    # $xPackages = Get-CMPackage | Select-object Name, PkgSourcePath, PackageID
    # Swap these \\ if -fast doesnt help
    $xPackages = Get-CMPackage -Fast | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) 
    {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    }
    $info
}
 
 
function GetInfoDriverPackage()
{
    $xPackages = Get-CMDriverPackage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) 
    {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
 
    }
    $info
}
 
 
function GetInfoBootimage()
{
    $xPackages = Get-CMBootImage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) 
    {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    
    }
    $info
}
 
 
function GetInfoOSImage()
{
    $xPackages = Get-CMOperatingSystemImage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) 
    {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    
    }
    $info
}
 
 
function GetInfoDriver()
{
    $xPackages = Get-CMDriver | Select-object LocalizedDisplayName, ContentSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) 
    {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.LocalizedDisplayName
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.ContentSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    
    }
    $info
}
 
 
function GetInfoSWUpdatePackage()
{
    $xPackages = Get-CMSoftwareUpdateDeploymentPackage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) 
    {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    
    }
    $info
}
 
 
 
function GetInfoApplications
{
   
    foreach ($Application in Get-CMApplication)
    {
 
        $AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
        $AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title
 
        foreach ($DeploymentType in $AppMgmt.DeploymentType)
        {
 
            # Calculate Size and convert to MB
            $size = 0
            foreach ($MyFile in $DeploymentType.Installer.Contents.Content.File)
            {
                $size += [int]($MyFile.GetAttribute("Size"))
            }
            $size = [math]::truncate($size / 1MB)
 
            # Fill properties
            $AppData = @{            
                AppName            = $AppName
                
                Location           = $DeploymentType.Installer.Contents.Content.Location
                DeploymentTypeName = $DeploymentType.Title.InnerText
                Technology         = $DeploymentType.Installer.Technology
                ContentId          = $DeploymentType.Installer.Contents.Content.ContentId
          
                SizeMB             = $size
            }                           
 
            # Create object
            $Object = New-Object PSObject -Property $AppData
    
            # Return it
            $Object
        }
    }
}
 
 
 
$initParams = @{}
Set-Location "$($SiteCode):\" @initParams
 
# Get the Data
Write-host "Applications" -ForegroundColor Yellow
$Applications = GetInfoApplications | select-object AppName, Location, Technology
$Applications | ogv
 
Write-host "Driver Packages" -ForegroundColor Yellow
$DriverPackage = GetInfoDriverPackage
$DriverPackage | ogv
 
Write-host "Drivers" -ForegroundColor Yellow
$Drivers = GetInfoDriver
$Drivers | ogv
 
Write-host "Boot Images" -ForegroundColor Yellow
$BootImages = GetInfoBootimage
$BootImages | ogv
 
Write-host "OS Images" -ForegroundColor Yellow
$OSImages = GetInfoOSImage
$OSImages | ogv
 
Write-host "Software Update Package Groups" -ForegroundColor Yellow
$SoftwareUpdates = GetInfoSWUpdatePackage
$SoftwareUpdates | ogv
 
Write-host "Packages" -ForegroundColor Yellow
$Packages = GetInfoPackages
$Packages | ogv