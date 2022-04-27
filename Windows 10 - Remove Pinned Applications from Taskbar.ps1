<#
.NOTES
   ===========================================================================
     Created on:    2019-05-29
     Created by:    Brian Thorp
    ===========================================================================
.Description
   This was code to attempt to unpin icons. Not supported and probably doesnt work :)
#>
$appnames = @("Microsoft Edge","Store")

foreach ($appname in $appnames)
{
    try 
    {
        ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $appname}).Verbs() | ?{$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{$_.DoIt(); $exec = $true}
        write-host "$AppName Removed"
    }
    catch
    {
        write-host "$AppName - Could not remove or app not pinned"
    }

}