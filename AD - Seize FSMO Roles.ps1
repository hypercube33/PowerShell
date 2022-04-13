<#
Brian Thorp
2017-01-25

Seize Solo DC roles to a new server
Was used to move roles from a SMB box to a real DC
#>
$NewPDC = "DC01"

Move-ADDirectoryServerOperationMasterRole -Identity $NewPDC -OperationMasterRole SchemaMaster, DomainNamingMaster, PDCEmulator, RIDMaster, InfrastructureMaster -Force