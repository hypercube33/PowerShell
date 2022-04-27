<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Renames all collections in a folder inside of CM to "ORIGINALNAME (Query)"
   This is to filter them out in our Computer Migration Tool
#>

$SiteCode = "CM1" # Site code 
$ProviderMachineName = "sccm.contoso.com" # SMS Provider machine name

$FolderName = 'Windows Versions' #Folder to scan
$ObjectType = '5000' #Collection ObjectType

$FolderIDQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_ObjectContainernode -Filter "Name='$FolderName' and ObjectType='$ObjectType'" -ComputerName $ProviderMachineName
    
$ItemsInFolder = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_ObjectContainerItem -Filter "ContainerNodeID='$($FolderIDQuery.ContainerNodeID)' and ObjectType='$ObjectType'" -ComputerName $ProviderMachineName

<#
$Collections = foreach($item in $ItemsInFolder)
{
    $id = $item.InstanceKey
    (Get-CMCollection -id $id).Name
}

$Collections #| Out-File C:\ContosoTemp\Collections.txt
#>


foreach($item in $ItemsInFolder)
{
    $id = $item.InstanceKey
    $ExistingName = (Get-CMCollection -id $id).Name
    $NewName = $ExistingName + " (Query)"
    Write-Host "$ExistingName | $NewName"
    Set-CMCollection -Name $ExistingName -NewName $NewName -Verbose
}
#Set-CMCollection -Name $CollName -NewName $NewCollName -Verbose