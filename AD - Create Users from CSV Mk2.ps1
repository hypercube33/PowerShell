
<#
.NOTES
   ===========================================================================
     Created on:    2022-02-18
     Created by:    Brian Thorp
    ===========================================================================

    CSV needs the following headers:
    GivenName
    Surname
    SamAccountName
    DisplayName
    Password
    UserPrincipalName
    OU
    Enabled

.Description
   Imports users from a CSV file and creates them in AD
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
    $OU          = $User.OU
    $Enabled     = $User.Enabled

    
    $OUExists = [adsi]::Exists("LDAP://$OU")
    # Write-Host "$OU"
    # Write-Host "OU Exists: $OUExists"
    
    # Check to see if user exists already
    if (Get-ADUser -Filter { SamAccountName -eq $UserName } )
    {
        Write-Warning "A user account with username $username already exists in Active Directory."
    }
    else
    {
        if ($OUExists)
        {
            Write-Host -ForegroundColor Green "   Information: OU Exists"

            New-ADUser `
            -SamAccountName $username `
            -UserPrincipalName "$username@$UPN" `
            -Name "$firstname $lastname" `
            -GivenName $firstname `
            -Surname $lastname `
            -Initials $initials `
            -Enabled $True `
            -DisplayName $DisplayName `
            -AccountPassword (ConvertTo-secureString $password -AsPlainText -Force) -ChangePasswordAtLogon $True `
            -Path $OU #`
            #-Whatif

            # If user is created, show message.
            Write-Host "The user account $username is created." -ForegroundColor Cyan
        }
        else
        {
            Write-Warning "OU Doesnt exist ($OU) so we're skipping $username -- check your CSV!!"
        }
        
    }
}