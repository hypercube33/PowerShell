<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Queries AD group(s) and lists users by username 
#>

import-module activedirectory

$Groups = @("Demo Group 1","Demo Group 2")

$SAMUsers = foreach ($Group in $Groups)
{
    Get-ADGroupMember -Identity $Group | Select SamAccountName
}

