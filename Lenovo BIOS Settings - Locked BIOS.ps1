<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Lenovo Machines - Checks to see if the bios is locked. Without this setting the password is basically useless
#>
function Get-LenovoBIOS
{
    param(
        $Setting
    )
    #Connect to the Lenovo_BiosSetting WMI class
    $SettingList = Get-WmiObject -Namespace root\wmi -Class Lenovo_BiosSetting

    #Return a list of all configurable settings
    #$SettingList | Select-Object CurrentSetting

    #Return a specific setting and value
    $GetSetting = $SettingList | Where-Object CurrentSetting -Like "$Setting*" | Select-Object -ExpandProperty CurrentSetting
    if ($GetSetting -eq "$Setting,Enable")
    {
        return $True;
    }
}

# -----------------------------------------------------------------------------------------------------------------------------------------
# Make your changes below - set variables per example per each piece of software required, or write your own function above 
# for specific software. Must return $True or $False
# Note for Get-ARPv you must pass a proper version number e.g 1.0 - wildcards are not supported
# -----------------------------------------------------------------------------------------------------------------------------------------

$Locked = Get-LenovoBios -Setting "LockBIOSSetting"


# -----------------------------------------------------------------------------------------------------------------------------------------
# -And all of your application test results below to return to SCCM if the application(s) are properly installed if there are multiple
# -----------------------------------------------------------------------------------------------------------------------------------------
if ($Locked)
{
    write-host "Installed"
}