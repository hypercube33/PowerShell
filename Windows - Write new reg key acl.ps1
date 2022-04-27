<#
.NOTES
   ===========================================================================
     Created on:    2022-03-16
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Code to modify a registry key to allow normal domain users to modify it.
#>
$RegistryPath = "HKLM:\SOFTWARE\Contoso Software"
if (!(Test-Path -Path $RegistryPath))
{
    New-Item -Path $RegistryPath -Force | Out-Null
}

$aclreg = Get-Acl "HKLM:\Software\"
$rulereg = New-Object System.Security.AccessControl.RegistryAccessRule("Contoso\Domain users","FullControl",@("ObjectInherit","ContainerInherit"),"None","Allow")#('Contoso\Domain users', "Full Control", $inheritreg,$propagationreg, "Allow")
$aclreg.SetAccessRule($rulereg)
$aclreg | set-acl -Path "HKLM:\Software\Contoso Software"