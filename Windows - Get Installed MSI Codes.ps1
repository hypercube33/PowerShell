<#
.NOTES
   ===========================================================================
     Created on:    2018-08-31
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Lists all MSI Installed Applications and ProductCodes
#>
get-wmiobject win32_product | select-object caption, identifyingnumber, name, localpackage | Out-GridView