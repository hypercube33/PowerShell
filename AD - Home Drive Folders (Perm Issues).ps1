<#
Brian Thorp
2018-05-08

Script to create home directories for users that may be missing them etc.


#>

# Home Drive Setup
$HomeDrive  =   "X:"
$UserRoot   =   "\\fileserver\fileshare\homedirroot\"

# ============================================================

# Get list of all AD Users
$users = get-aduser -searchbase "OU=Users,OU=Corporate,DC=ad,DC=contoso,DC=k12,DC=wi,DC=us" -Filter *

foreach ($user in $users)
{
    Try
    {
        $accountname = $user.samaccountname

        # Put above together for the full path
        $HomeDirectory=$UserRoot+$AccountName

        write-host "--------------------------------------"
        write-host "Current user: $accountname"
        write-host "--------------------------------------"

        # ------------------------------------------------------
        # Create the users home folder if it doesnt exist
        # ------------------------------------------------------
        if(Test-Path $HomeDirectory)
        {
            write-host -ForegroundColor yellow "   Home Folder Exists"
        }
        else
        {
            # Create Folder
            new-item -path $HomeDirectory -type directory -force
            write-host -ForegroundColor Green "   Command issued to create folder"
        }

        # ------------------------------------------------------
        # Set the appropriate ACLs on the folder
        # ------------------------------------------------------

        # get current acl permissions
        $acl = get-acl -path $HomeDirectory

        # Setup new permission (FullControl, Modify, Read)
        $permission = $accountname, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
        $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
        
        # Add The New Permissions
        $acl.AddAccessRule($rule)

        # set new permissions
        $acl | Set-Acl -Path $HomeDirectory

        write-host -ForegroundColor Green "   Folder's ACL Set"
        
        # ------------------------------------------------------

        # ------------------------------------------------------

        # Set AD Properties Accordingly
        SET-ADUSER $AccountName -HomeDrive $HomeDrive -HomeDirectory $HomeDirectory

        write-host "Account Name:       $AccountName"
        write-host "Home Drive Letter:  $HomeDrive"
        write-host "Home Directory:     $HomeDirectory"
        write-host ""
    }
    Catch
    {
        write-host -foregroundcolor red "General Failure"
    }
}