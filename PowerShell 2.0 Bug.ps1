<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Demo of an issue we had with Windows 7 machines not handling IsNullOrEmpty
#>
function Demo-Function
{
    param(
        $DisplayName,
        $FileFlag
    )

    # This fails in powershell 2.0
    if ($Null -ne $FileFlag)
    {
        Write-host "File flag is $Fileflag"
    }

    if (-not [string]::IsNullOrEmpty($FileFlag))
    {
        Write-Host "Moo!!!!"
    }
}

Demo-Function -DisplayName "Java*" -FileFlag "Java"