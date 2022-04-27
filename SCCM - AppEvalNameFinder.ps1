<##############################################################################
Lists Unique IDs for Deployment Types - Needed this since some logs just
 refer to these only


##############################################################################>
# =============================================================================
# Import Modules
# =============================================================================
# -----------------------------------------------------------------------------
# SCCM (Requires Console Installed on machine)
# -----------------------------------------------------------------------------
Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction SilentlyContinue

# =============================================================================
# Connect to SCCM
# =============================================================================
# Grab the site server information
$SiteInfo                           = Get-PSDrive -PSProvider CmSite

# Site Code
$SiteCode                           = $SiteInfo.Name

# FQDN of Site Server
$SiteServer                         = $SiteInfo.Root

# =============================================================================
# List Deployment Types + CIUniqueID
# =============================================================================

$APPQuery = Get-CIMInstance -ComputerName $SiteServer -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_DeploymentType
#$APPQuery.CI_UniqueID

$APPQuery | Select LocalizedDisplayName, CI_UniqueID | ogv



$APPQuery | ogv