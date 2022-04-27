#Requires -version 2.0
# ***************************************************************************
#
# File:      SystemManagement.ps1
#
# Version:   2.0
#
# Author:    Michael Niehaus (1.0), Brian Thorp (Updated)
#
# Purpose:   Create the AD "System Management" container needed for
#            ConfigMgr 2007 and 2012, and grant access to the current
#            computer account.
#
#            This requires PowerShell 2.0 and Windows Server 2008 R2.
#            Tested on Server 2022.
#
# Usage:     Run this script as a domain administrator, from the ConfigMgr
#            server.  No parameters are required.
#
# ------------- DISCLAIMER -------------------------------------------------
# This script code is provided as is with no guarantee or waranty concerning
# the usability or impact on systems and may be used, distributed, and
# modified in any way provided the parties agree and acknowledge the
# Microsoft or Microsoft Partners have neither accountabilty or
# responsibility for results produced by use of this script.
#
# Microsoft will not provide any support through any means.
# ------------- DISCLAIMER -------------------------------------------------
#
# ***************************************************************************
$SCCMServer = "sccmserver123"

# Load the AD module
Import-Module ActiveDirectory

# Figure out our domain
$root = (Get-ADRootDSE).defaultNamingContext
$LDAP = "CN=System Management,CN=System,$root"

# Get, or create the System Management container
$SystemManagementContainerExists = [adsi]::Exists("LDAP://$LDAP")

$ou = $null
if ($SystemManagementContainerExists)
{
    $ou = Get-ADObject "$LDAP"
    Write-Host -ForegroundColor Yellow "System Management Exists; $OU"
}
else
{
    Write-Verbose "System Management container does not currently exist; Creating..."
    $ou = New-ADObject -Type Container -name "System Management" -Path "CN=System,$root" -Passthru
}


# Get the current ACL for the OU
$acl = get-acl "ad:$LDAP"

# Get the computer's SID
#$computer = get-adcomputer $env:ComputerName
$Computer = get-adcomputer $SCCMServer

# ==========================================================================
# https://social.technet.microsoft.com/Forums/Lync/en-US/df3bfd33-c070-4a9c-be98-c4da6e591a0a/forum-faq-using-powershell-to-assign-permissions-on-active-directory-objects?forum=winserverpowershell
$SysManObj = [ADSI]("LDAP://$LDAP")

$sid = [System.Security.Principal.SecurityIdentifier] $computer.SID

$identity = [System.Security.Principal.IdentityReference] $SID

# New ACL Permissions
$adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
$type = [System.Security.AccessControl.AccessControlType] "Allow"
$inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType #set permission

$SysManObj.psbase.ObjectSecurity.AddAccessRule($ACE)

$SysManObj.psbase.commitchanges()
# ==========================================================================
