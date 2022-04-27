<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Code to attempt automation of downloaded Windows 10 iso files -> SCCM import
   NOT FINISHED
#>
$ISO        =       "C:\ISO\SW_DVD9_Win_Pro_10_1903_64BIT_English_Pro_Ent_EDU_N_MLF_X22-02890.ISO"
$Temp       =       "C:\Temp\"

###########################################################################################################################################
# Unpack and examine and move the ISO File contents to SCCM
###########################################################################################################################################
# Mount the ISO
$ISOMount = Mount-DiskImage -ImagePath $ISO -PassThru

# Get the drive letter of our mount
$DriveLetter = ($ISOMount | Get-Volume).DriveLetter

# Get WIM Path
$WIM = $DriveLetter + ":\sources\install.wim"

Get-WindowsImage -ImagePath $WIM


$Share      =       "sources"
$OS         =       "Windows 10"
$build      =       "1903"
$arch       =       "x64"
$family     =       "Enterprise"

###########################################################################################################################################
# -----------------------------------------------------------------------------
# Import Modules
# -----------------------------------------------------------------------------
# Active Directory
Import-Module ActiveDirectory -Cmdlet New-ADGroup, Add-ADGroupMember, Get-ADDomain

# SCCM
Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction SilentlyContinue

# -----------------------------------------------------------------------------
# Connect to SCCM
# -----------------------------------------------------------------------------
# Grab the site server information
$SiteInfo                           = Get-PSDrive -PSProvider CmSite

# Site Code
$SiteCode                           = $SiteInfo.Name

# FQDN of Site Server
$SiteServer                         = $SiteInfo.Root

# -----------------------------------------------------------------------------
# Source Directories
# -----------------------------------------------------------------------------

$ContentLibrary                     = "\\$SiteServer\$Share\Operating Systems\"
###########################################################################################################################################