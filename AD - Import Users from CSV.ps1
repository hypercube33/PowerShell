<#
.NOTES
   ===========================================================================
     Created on:    2022-02-18
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Imports users from a CSV (AD - Export Users to CSV2.ps1)
#>
$ImportedUsers = Import-CSV C:\ContosoTemp\ADUsers.csv

foreach ($User in $ImportedUsers)
{
    # Get usable variables for each csv row
    $FirstName   = $User.GivenName
    $LastName    = $User.Surname
    $UserName    = $User.SamAccountName
    $DisplayName = $User.DisplayName
    $Password    = $User.Password
    $UPN         = $User.UserPrincipalName
    $OU          = $User."Common Name"
    $Enabled     = $User.Enabled
    
    # Check to see if user exists already
    if (Get-ADUser -Filter { SamAccountName -eq $UserName } )
    {
        Write-Warning "A user account with username $username already exists in Active Directory."
    }
    else
    {
        New-ADUser `
            -SamAccountName $username `
            -UserPrincipalName "$username@$UPN" `
            -Name "$firstname $lastname" `
            -GivenName $firstname `
            -Surname $lastname `
            -Initials $initials `
            -Enabled $True `
            -DisplayName $DisplayName `
            -AccountPassword (ConvertTo-secureString $password -AsPlainText -Force) -ChangePasswordAtLogon $True

        # If user is created, show message.
        Write-Host "The user account $username is created." -ForegroundColor Cyan
    }
}