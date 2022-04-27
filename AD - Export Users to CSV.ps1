<#
.NOTES
   ===========================================================================
     Created on:    2022-02-17
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Exports AD users to a CSV File
#>
Get-AdUser -Filter * | Select-Object GivenName, Surname, SamAccountName, DisplayName, UserPrincipalName, DistinguishedName, Enabled `
| Export-CSV "C:\ContosoTemp\ADUsers.csv" -NoType