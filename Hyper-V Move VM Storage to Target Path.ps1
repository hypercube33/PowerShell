<#
Brian Thorp
2022-04-12

Moves Hyper-V VMs on localhost to another drive.

Keeps the folders clean

#>
$Destination = "E:\VM\"

$VMs = Get-VM

foreach($vm in $VMs)
{
    $name = $vm.name
    Move-VMStorage -VMName "$name" -DestinationStoragePath "$Destination\$name" -asjob
}