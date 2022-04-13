<#
Brian Thorp
2016-07-20

Updates UPN Names to new UPN e.g. Corporate Takeover
Run lines step by step 
#>

# General:
# Requires Windows Management Framework 4.0
# Here is the link to the upgrade package:
# https://www.microsoft.com/en-us/download/details.aspx?id=40855

# You may need to apply .NET 4.5.1 prior to the above:
# https://www.microsoft.com/en-us/download/details.aspx?id=40779


# Review of the AD UPN:
Get-ADUser -Filter * -Properties DisplayName, UserPrincipalName, Title | select DisplayName, UserPrincipalName, Title | Out-GridView

#Replace with the old suffix
$oldSuffix = 'olddomain.com'

#Replace with the new suffix
$newSuffix = 'newdomain.net'

#Replace with the OU you want to change suffixes for
#$ou = "DC=sample,DC=domain"

#Replace with the name of your AD server
$server = "domaincontrollername"

Get-ADUser -filter * | ForEach-Object
{
    #Setup the new suffix per user
    $newUpn = $_.UserPrincipalName.Replace($oldSuffix,$newSuffix)

    #Apply the suffix to AD
    $_ | Set-ADUser -server $server -UserPrincipalName $newUpn
}
