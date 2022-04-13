<#
Brian Thorp
2018-04-30

Dumps current user home directories and mapped drive letters to a CSV
#>

Get-ADUser -filter * -properties homedrive, homedirectory | select-object name, homedrive, homedirectory | export-csv C:\homedir.csv