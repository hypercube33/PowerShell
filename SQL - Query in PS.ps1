<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Demo code from somewhere online and my awful SQL code to list computers with specific applications
#>
$Query = @"
SELECT
	UserData.Full_User_Name0 as 'Full User Name',
	UserData.Unique_User_Name0 as 'UserName',
	[CM_CM1].[dbo].[v_R_System].Netbios_Name0 as 'Computer Name',
	Publisher0,
	ARPDisplayName0,
	ProductVersion0,
	LocalPackage0,
	UninstallString0,
	PackageCode0,
	v_GS_INSTALLED_SOFTWARE.ResourceID


FROM	[CM_CM1].[dbo].[v_GS_INSTALLED_SOFTWARE]
		INNER JOIN [CM_CM1].[dbo].[v_R_System]
		ON v_GS_INSTALLED_SOFTWARE.ResourceID = v_R_System.ResourceID

/* Need to put in differnt user lookup for primary user */
Outer APPLY
	(
		SELECT top 1

		v_R_User.Full_User_Name0,
		v_R_User.Unique_User_Name0,
		v_R_System_Valid.User_Name0,
		v_R_System_Valid.Netbios_Name0

		From [CM_CM1].[dbo].[v_R_System_Valid]

		INNER JOIN [CM_CM1].[dbo].[v_UserMachineRelationship]
		ON v_R_System_Valid.ResourceID = v_GS_INSTALLED_SOFTWARE.ResourceID

		INNER JOIN [CM_CM1].[dbo].[v_R_User]
		ON v_R_User.User_Name0 = v_R_System_Valid.User_Name0


		/*
		Select Top 1

		MachineResourceName,
		MachineResourceID,
		UniqueUserName

		From [CM_CM1].[dbo].[v_UserMachineRelationship]

		Where MachineResourceID = v_GS_INSTALLED_SOFTWARE.ResourceID
		*/
	) As UserData


WHERE ARPDisplayName0 LIKE 'Microsoft Office 365 ProPlus%' and Publisher0 LIKE '%' and ProductVersion0 LIKE '%'
"@



$ServerName = "sccm.contoso.com"
$DatabaseName = "CM_CM1"

#Timeout parameters
$QueryTimeout = 120
$ConnectionTimeout = 30

#Action of connecting to the Database and executing the query and returning results if there were any.
$conn=New-Object System.Data.SqlClient.SQLConnection
$ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerName,$DatabaseName,$ConnectionTimeout
$conn.ConnectionString=$ConnectionString
$conn.Open()
$cmd=New-Object system.Data.SqlClient.SqlCommand($Query,$conn)
$cmd.CommandTimeout=$QueryTimeout
$ds=New-Object system.Data.DataSet
$da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.fill($ds)
$conn.Close()

$Results = $ds.Tables

$Affected = Import-CSV -Path "C:\ContosoTemp\onenote_issues.csv"

foreach ($Entry in $Results)
{
    $Computer = $Entry.'Computer Name'
    $Version = $Entry.'ProductVersion0'

    if ($($Affected.Computer) -contains $Computer)
    {
        $Computer
        $Version
    }
}
