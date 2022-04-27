<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Modified code found on the web to list all collections in a folder from the console
#>
$SiteCode = "CM1" # Site code 
$ProviderMachineName = "sccm.contoso.com" # SMS Provider machine name

$FolderName = 'Departments' #Folder to scan
$ObjectType = '5000' #Collection ObjectType

$FolderIDQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_ObjectContainernode -Filter "Name='$FolderName' and ObjectType='$ObjectType'" -ComputerName $ProviderMachineName
    
$ItemsInFolder = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_ObjectContainerItem -Filter "ContainerNodeID='$($FolderIDQuery.ContainerNodeID)' and ObjectType='$ObjectType'" -ComputerName $ProviderMachineName

$Collections = foreach($item in $ItemsInFolder)
{
    $id = $item.InstanceKey
    (Get-CMCollection -id $id).Name
}

$Collections #| Out-File C:\ContosoTemp\Collections.txt
