<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Searches for a string for AnyConnect client's connection and replaces it with a new one. 
   Use case is if you're replacing a router and it has a new name side by side
#>
$users = Get-ChildItem -Directory -Path C:\Users\

ForEach($user in $users)
{
    $XMLPath = "C:\Users\$User\AppData\Local\Cisco\Cisco AnyConnect Secure Mobility Client\preferences.xml"
    write-host "Checking: $User"
    
    # Look for xml file
    if (Test-Path $XMLPath)
    {
        $Search =  "oldvpn.contoso.com"
        $Replace = "newvpn.contoso.com"
        # write-host "Testing $XMLPath"
        # $content = [System.IO.File]::ReadAllText("$XMLPath").Replace("KTVPN.Contoso.com", "KTVPN2.Contoso.com")
        $content = [System.IO.File]::ReadAllText("$XMLPath")
        $writefile = ($content -match $search)

        write-host "   Search String found in file - (True/False): $writefile"
        if ($writefile)
        {
            $found = $matches[0]
            write-host "   $found to be replaced with $Replace"
            # Write-Log -Message "Search String Found in file - $writefile" -Source 'main' -LogType 'CMTrace'

            $content = $content -replace $Search, $Replace
            # Write the file
            [System.IO.File]::WriteAllText("$XMLPATH", $content)
        }
    }
}