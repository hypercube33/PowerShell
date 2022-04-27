<#
.NOTES
   ===========================================================================
     Created on:    2022-02-23
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Takes CSV of SAMAccountName and Returns Display Name | Email Address | Title
#>
import-module activedirectory

$Users = (Import-CSV C:\ContosoTemp\WindowsTest.csv).SAMAccountName

$Output = foreach ($User in $Users)
{
    Get-ADUser -identity $User -Properties DisplayName, EmailAddress, Title | select DisplayName, EmailAddress, Title
}
