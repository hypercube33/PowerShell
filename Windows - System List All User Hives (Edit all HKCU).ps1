# Code snip from https://www.pdq.com/blog/modifying-the-registry-users-powershell/
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