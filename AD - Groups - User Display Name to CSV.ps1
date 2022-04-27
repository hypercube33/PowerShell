<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Exports AD usernames from a specific group to a CSV file
#>

$ADGroupUsers = Get-ADGroupMember -Identity Group_Active_Users_AD

$ADGroupUsers.name | Export-CSV "C:\ContosoTemp\Group_Active_Users.csv" -NoTypeInformation