<#
.NOTES
   ===========================================================================
     Created on:    2019-02-07
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Checks each domain controller for a computer object for replication purposes
#>

$ErrorActionPreference = 'SilentlyContinue'
$DCs = (Get-ADForest).Domains | %{ Get-ADDomainController -Filter * -Server $_ }
$computer = "*meskitport4*"

foreach ($DC in $DCs)
{
    $AD_Computer = $null
    write-host "Searching on $DC"
    $AD_Computer = Get-ADComputer -Server $DC -Identity $computer #-ErrorAction SilentlyContinue

    if ($null -eq $AD_Computer) # Empty
    {
        write-host "Computer NOT found on $DC" -ForegroundColor RED
    }
    else
    {
        write-host "Computer found on $DC" -ForegroundColor Green
    }

}

$ErrorActionPreference = 'Continue'