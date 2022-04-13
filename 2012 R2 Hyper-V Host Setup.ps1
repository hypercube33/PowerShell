<#
Brian Thorp
2016-04-15

Example script to setup an out-of-box Server 201x Install -> Hyper-V Host
Storage Spaces tiering is employed

#>
Rename-Computer -NewName "s-hyperv1" -Restart

# Install Hyper-V Role
Install-WindowsFeature Hyper-V -IncludeManagementTools –Restart

# Install Storage Pool Features
Install-WindowsFeature File-Services, FS-FileServer

# List the Disks that are able to be added to a storage pool
Get-PhysicalDisk -CanPool $true

# Create new storage spaces pool with all Non-RAID Disks
New-StoragePool -StorageSubSystemFriendlyName *Spaces* -FriendlyName "TierPool" -PhysicalDisks (Get-PhysicalDisk -CanPool $true)

# Storage Tiers
$ssd = New-StorageTier -StoragePoolFriendlyName "TierPool" -FriendlyName SS_SSD -MediaType SSD
$ssd_size = Get-StorageTierSupportedSize -FriendlyName SS_SSD         
$hdd = New-StorageTier -StoragePoolFriendlyName "TierPool" -FriendlyName SS_HDD -MediaType HDD
$hdd_size = Get-StorageTierSupportedSize -FriendlyName SS_HDD

# Create a virtual disk on the new pool
New-VirtualDisk -FriendlyName "SS Storage" -StoragePoolFriendlyName TierPool -StorageTiers @($ssd, $hdd) -StorageTierSizes @($ssd_size.TierSizeMax,$hdd_size.tiersizemax) -ProvisioningType Fixed -ResiliencySettingName Mirror

# Format New VD
Get-VirtualDisk -FriendlyName "SS Storage" | Initialize-Disk -PassThru -PartitionStyle GPT | New-Partition -AssignDriveLetter D -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "SS Data" -Confirm:$false
