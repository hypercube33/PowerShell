<#
.NOTES
   ===========================================================================
     Created on:    2022-02-18
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Exports AD users to a CSV File (This is the more advanced version for re-import)
#>

$ADData = Get-AdUser -Filter * | Select-Object GivenName, Surname, SamAccountName, DisplayName, UserPrincipalName, DistinguishedName, Enabled

$NewData = New-Object PSObject

foreach($User in $ADData)
{
    $FirstName   = $User.GivenName
    $LastName    = $User.Surname
    $UserName    = $User.SamAccountName
    $DisplayName = $User.DisplayName
    $Password    = $User.Password
    $UPN         = $User.UserPrincipalName
    $Enabled     = $User.Enabled

    $DistinguishedName = $User.DistinguishedName
    $OU = [regex]::match($DistinguishedName, '(?=OU)(.*\n?)(?<=.)').Value
    

    $ChangedRow = New-Object PSObject
    $ChangedRow | Add-Member -MemberType NoteProperty -Name "UserName" -Value "Default"
}


Export-CSV "C:\ContosoTemp\ADUsers.csv" -NoType