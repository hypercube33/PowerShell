<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Digs through every user profile (HKCU per user) and dumps mapped drives
   Extended information
   Dumps the information to a csv file per machine into the sources\logs directory to be used
#>

# Computer Name, User Name, Drive Letter, Mapped Path
$SystemsMappedDrives = @()

# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
 
# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -match $PatternSID } | 
Select-Object  @{name = "SID"; expression = { $_.PSChildName } }, 
@{name = "UserHive"; expression = { "$($_.ProfileImagePath)\ntuser.dat" } }, 
@{name = "Username"; expression = { $_.ProfileImagePath -replace '^(.*[\\\/])', '' } }
 
# Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
$LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildname -match $PatternSID } | Select-Object @{name = "SID"; expression = { $_.PSChildName } }
 
# Get all users that are not currently logged
$UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name = "SID"; expression = { $_.InputObject } }, UserHive, Username

# Loop through each profile on the machine
Foreach ($UserProfile in $ProfileList)
{
    # Load User ntuser.dat if it's not already loaded
    IF ($UserProfile.SID -in $UnloadedHives.SID)
    {
        reg load HKU\$($UserProfile.SID) $($UserProfile.UserHive) | Out-Null
    }
 

    #####################################################################
    # This is where you can read/modify a users portion of the registry 
 
    # This example lists the Uninstall keys for each user registry hive
    # "{0}" -f $($item.Username) | Write-Output

    
    $Username = $UserProfile.Username
    #Write-Host "Checking $Username"

    #$MappedDrives = Get-ChildItem registry::HKCU\Network
    $MappedDrives = Get-ChildItem registry::HKEY_USERS\$($UserProfile.SID)\Network

    foreach ($MappedDrive in $MappedDrives)
    {
        $DriveLetter = Split-Path $MappedDrive.Name -Leaf
        
        $MappedPath = (Get-ItemProperty -Path registry::HKEY_USERS\$($UserProfile.SID)\Network\$DriveLetter).RemotePath

        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -MemberType NoteProperty -Name Computer -Value $env:computername
        $obj | Add-Member -MemberType NoteProperty -Name UserName -Value $Username
        $obj | Add-Member -MemberType NoteProperty -Name DriveLetter -Value $DriveLetter
        $obj | Add-Member -MemberType NoteProperty -Name DrivePath -value $MappedPath
            
        $SystemsMappedDrives += $obj
    }


    #####################################################################
 
    # Unload ntuser.dat        
    if ($UserProfile.SID -in $UnloadedHives.SID)
    {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        try {reg unload HKU\$($UserProfile.SID) | Out-Null} Catch {}
    }
}

$HostName = $env:COMPUTERNAME
$OutPath = "\\sccmserver\sources\Logs\MappedDrives\$HostName.csv"


# ===================================================================================
if (Test-Connection -ComputerName "sccmserver" -Count 1 -Quiet)
{
    if (-not (Test-Path ($OutPath)))
    {
        Write-Host "Writing file"
        # $SystemsMappedDrives | ConvertTo-CSV | Out-File $OutPath
        $SystemsMappedDrives | Export-Csv -Path $OutPath
    }
    else
    {
        Write-Host "File Already Updated"
    }
}
else
{
    Write-Host "Cannot Reach SCCM Share"    
}
    
