<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   POC to list extensions chrome has installed per user
#>
$ChromeDataPath = "\AppData\Local\Google\Chrome\User Data\Default\Extensions"

# Google Drive, Youtube, Gmail, + other unkown built in extensions
$ExcludedID = @('apdfllckaahabafndbhieahigkjlhalf','blpcfgokakmgnkcojhhkbfbldkacnbeo','pjkljhegncpnkpknbcohdijeoejaedia','fedbieoalmbobgfjapopkghdmhgncnaa','nmmhkkegccagdldgiimedpiccmgmieda','pkedcjkdefgpdelpbcmbmeomcjbeemfm')

function Get-AppName
{
    param(
        $id
    )

    #https://groups.google.com/a/chromium.org/forum/#!topic/chromium-extensions/U0NP0dh0mmM
    $URI = 'https://chrome.google.com/webstore/detail/'
    

    $data = try{Invoke-WebRequest -Uri ($URI + $id) | select Content}catch{}
    $data = $data.Content
    # Regex which pulls the title from og:title meta property
    $title = [regex] '(?<=og:title" content=")([\S\s]*?)(?=">)' 
    $out_title = $title.Match($data).value.trim() 

    $results = @(New-Object PSObject -Property @{'extension id'=$id; Name=$Out_Title})
    
    return $results
}



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

$ChromeExtensions = foreach ($UsrProfile in $Profilelist)
{
    $UserHive = $UsrProfile.UserHive
    $UserName = $UsrProfile.UserName
    $Hostname = $env:COMPUTERNAME
    $ExtensionsInstalled = $null

    $UserDir = Split-Path -Path $UserHive -Parent

    $UserChromePath = $UserDir + $ChromeDataPath
    if (Test-Path $UserChromePath)
    {
        $ExtensionsInstalled = $(Get-ChildItem -Path $UserChromePath).name
    }

    foreach ($URI in $ExtensionsInstalled)
    {
        if ($ExcludedID -notcontains $uri)
        {
            $AppRes = Get-AppName -id $uri

            $ExtName = $AppRes.Name

            New-Object PSObject -Property @{'Computer Name' = $HostName;UserName=$UserName; ExtensionID=$uri; 'Extension Name'=$ExtName}
        }   
    }

}


##########################
$ChromeExtensions | Ogv