<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Two functions written for Migration Tool
#>
function Get-Collections ($hostname)
{

    $ResID = (Get-CMDevice -Name "$hostname").ResourceID
    $Collections = (gWMI -Namespace "root\SMS\Site_$SiteCode" -Class sms_fullcollectionmembership -Filter "ResourceID = '$($ResID)'").CollectionID

    foreach ($Collection in $Collections)
    {
        Get-CMDeviceCollection -CollectionId $Collection -WarningAction SilentlyContinue | select Name, CollectionID
    }
}


function Get-CMCollectionsMemberOf
{
    param(
        $SiteCode,
        $SiteServer,
        $ComputerName
    )
    (Get-WmiObject -ComputerName $SiteServer -Namespace "Root\SMS\Site_$SiteCode" -Query “SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$hostname' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID”)
}