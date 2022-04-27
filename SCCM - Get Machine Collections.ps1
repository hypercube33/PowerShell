<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Code written for Machine Migration Tool to list all of its collections BUT filter some out
#>
$hostname = "DemoMachine"

    $Collections = (Get-WmiObject -ComputerName $SiteServer -Namespace "Root\SMS\Site_$SiteCode" -Query “SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$hostname' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID”)

    $List = $($Collections.Name)

    # Exclusion List
    $Match1 = "Query"
    $Match2 = "All"
    $Match3 = "Department"
    $Match4 = "Windows Updates Prod Group"
    $Match5 = "Staging"
    $Match6 = "Machines NOT Windows 10 1909"
    $Match7 = "Windows Analytics Script"
    $Match8 = "Device Admin Software"
    $Match9 = "Windows 11 Updates"
    $Match10 = "Approved 1909 Models"

    # Filter using exlusion list
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
    | Where-Object {$_ -notmatch $Match10} `
    | Where-Object {$_ -like "* - Manual Target"}

$NewContent
