<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
     https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
    ===========================================================================
.Description
   Some code to query sql via powershell
#>

$SiteCode = "CM1" # Site code 
$ProviderMachineName = "sccm.contoso.com" # SMS Provider machine name

# Code to get collections machine is a part of
# https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
$hostname = "DemoDevice"
<#
$Collections = (Get-WmiObject -ComputerName $ProviderMachineName -Namespace "Root\SMS\Site_$SiteCode" -Query “SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$hostname' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID”)

$Collections | Where-Object {$_.Name -notcontains "Query" } | select name
#>

Get-WmiObject -ComputerName $ProviderMachineName -Namespace "Root\SMS\Site_$SiteCode" `
            -Query ("select InstalledLocation,ProductVersion,ProductName,ARPDisplayName,Publisher
            from 
                SMS_R_System
            join 
                SMS_G_SYSTEM_Installed_Software on SMS_R_System.ResourceID = 
                SMS_G_SYSTEM_Installed_Software.ResourceID
            where
                SMS_R_SYSTEM.Name= ""$($hostname)"" ”) |
 
            Select-Object -Property Publisher, ARPDisplayName,ProductVersion, InstalledLocation | 
            Sort-Object Publisher