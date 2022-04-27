# https://webcache.googleusercontent.com/search?q=cache:9uQZl9nYyqgJ:https://www.configjon.com/lenovo-bios-settings-management/+&cd=3&hl=en&ct=clnk&gl=us

#Connect to the Lenovo_BiosSetting WMI class
$SettingList = Get-WmiObject -Namespace root\wmi -Class Lenovo_BiosSetting

#Return a list of all configurable settings
#$SettingList | Select-Object CurrentSetting

#Return a specific setting and value
$GetSetting = $SettingList | Where-Object CurrentSetting -Like "LockBIOSSetting*" | Select-Object -ExpandProperty CurrentSetting
if ($GetSetting -eq "LockBIOSSetting,Enable")
{
    Write-Host "Installed"
}
# =============================

# The second WMI class is Lenovo_SetBiosSetting. This class contains a method called SetBiosSetting which is used to modify bios setting values.

#Connect to the Lenovo_SetBiosSetting WMI class`
$Interface = Get-WmiObject -Namespace root\wmi -Class Lenovo_SetBiosSetting

# Set a specific BIOS setting when a BIOS password is not set
#$Interface.SetBiosSetting("LockBIOSSetting,Enabled")

# Set a specific BIOS setting when a BIOS password is set
$Interface.SetBiosSetting("LockBIOSSetting,Enable,ITSC671,ascii,us")

# The third WMI class is Lenovo_SaveBiosSetting. This class contains a method called SaveBiosSettings which is used to commit any changes made to BIOS setting values.

#Connect to the Lenovo_SaveBiosSetting WMI class
$SaveSettings = Get-WmiObject -Namespace root\wmi -Class Lenovo_SaveBiosSettings

#Save any outstanding BIOS configuration changes (no password set)
# $SaveSettings.SaveBiosSettings()

#Save any outstanding BIOS configuration changes (password set)
$SaveSettings.SaveBiosSettings("ITSC671,ascii,us")

# The fourth WMI class is Lenovo_BiosPasswordSettings. This class is used to query the current status of the BIOS passwords.

#Connect to the Lenovo_BiosPasswordSettings WMI class
#$PasswordSettings = Get-WmiObject -Namespace root\wmi -Class Lenovo_BiosPasswordSettings

#Check the current password configuration state
# $PasswordSettings.PasswordState