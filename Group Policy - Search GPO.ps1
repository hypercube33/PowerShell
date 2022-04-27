# https://dailysysadmin.com/KB/Article/2304/search-all-gpos-in-a-domain-for-some-text/
# Get the string we want to search for 
$string = Read-Host -Prompt "What string do you want to search for?" 
 
# Set the domain to search for GPOs 
$DomainName = $env:USERDNSDOMAIN 
 
# Find all GPOs in the current domain 
write-host "Finding all the GPOs in $DomainName" 
Import-Module grouppolicy 
$allGposInDomain = Get-GPO -All -Domain $DomainName 
[string[]] $MatchedGPOList = @()

# Look through each GPO's XML for the string 
Write-Host "Starting search...." 
foreach ($gpo in $allGposInDomain) { 
    $report = Get-GPOReport -Guid $gpo.Id -ReportType Xml 
    if ($report -match $string) { 
        write-host "********** Match found in: $($gpo.DisplayName) **********" -foregroundcolor "Green"
        $MatchedGPOList += "$($gpo.DisplayName)";
    } # end if 
    else { 
        Write-Host "No match in: $($gpo.DisplayName)" 
    } # end else 
} # end foreach
write-host "`r`n"
write-host "Results: **************" -foregroundcolor "Yellow"
foreach ($match in $MatchedGPOList) { 
    write-host "Match found in: $($match)" -foregroundcolor "Green"
}