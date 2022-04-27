<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Collection lookup with array filtering on output
#>
$SiteCode = "CCM" # Site code 
$ProviderMachineName = "sccm.contoso.com" # SMS Provider machine name
# ======================================================================
# Code to get collections machine is a part of
# ======================================================================
$hostname = "DemoComputer"
$Collections = (Get-WmiObject -ComputerName $ProviderMachineName -Namespace "Root\SMS\Site_$SiteCode" -Query “SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$hostname' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID”)

$List = $($Collections.Name)


$Match1 = "Query"
$Match2 = "All"
$Match3 = "Department"
$Match4 = "matchtext4"
$Match5 = "matchtext5"
$Match6 = "matchtext6"
$Match7 = "matchtext7"
$Match8 = "matchtext8"
$Match9 = "matchtext9"
$Match10 = "matchtext10"


$OldContent = $List
$NewContent = $OldContent `
| Where-Object {$_ -notmatch $Match1} `
| Where-Object {$_ -notmatch $Match2} `
| Where-Object {$_ -notmatch $Match3} `
| Where-Object {$_ -notmatch $Match4} `
| Where-Object {$_ -notmatch $Match5} `
| Where-Object {$_ -notmatch $Match6} `
| Where-Object {$_ -notmatch $Match7} `
| Where-Object {$_ -notmatch $Match8} `
| Where-Object {$_ -notmatch $Match9} `
| Where-Object {$_ -notmatch $Match10}

$NewContent
# ======================================================================
# Make the above have an exclude or not
# ======================================================================
# Cast the collection array to an array list so we can add or remove from it
$NewContent = [System.Collections.ArrayList]$OldDeviceCollections