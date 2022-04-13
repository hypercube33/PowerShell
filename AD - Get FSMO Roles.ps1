<#
Brian Thorp
2017-04-09

Outputs AD Server Role Holders
#>

Get-ADForest | Select SchemaMaster, DomainNamingMaster | Format-List
Get-ADDomain | Select PDCEmulator, RIDMaster, InfrastructureMaster | Format-List