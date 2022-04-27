<#
.NOTES
   ===========================================================================
     Created on:    2019-03-11
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Allows functionality to log to CMTrace friendly logs
   Inspiration:
    https://www.adamtheautomator.com/building-logs-for-cmtrace-powershell/
    https://blogs.msdn.microsoft.com/rslaten/2014/07/28/logging-in-cmtrace-format-from-powershell/
#>
$Global:CMLogFilePath   = "C:\ContosoTemp\testcmtrace.log"
$Global:CMLogFileSize   = "40"

function Start-CMTraceLog
{
    # Checks for path to log file and creates if it does not exist
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
            
    )

    $indexoflastslash = $Path.lastindexof('\')
    $directory = $Path.substring(0, $indexoflastslash)

    if (!(test-path -path $directory))
    {
        New-Item -ItemType Directory -Path $directory
    }
    else
    {
        # Directory Exists, do nothing    
    }
}

function Write-CMTraceLog
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
            
        [Parameter()]
        [ValidateSet(1, 2, 3)]
        [int]$LogLevel = 1,

        [Parameter()]
        [string]$Component,

        [Parameter()]
        [ValidateSet('Info','Warning','Error')]
        [string]$Type
    )
    $LogPath = $Global:CMLogFilePath

    Switch ($Type)
    {
        Info {$LogLevel = 1}
        Warning {$LogLevel = 2}
        Error {$LogLevel = 3}
    }

    # Get Date message was triggered
    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"

    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'

    # When used as a module, this gets the line number and position and file of the calling script
    # $RunLocation = "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)"

    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), $Component, $LogLevel
    $Line = $Line -f $LineFormat

    # Write new line in the log file
    Add-Content -Value $Line -Path $LogPath

    # Roll log file over at size threshold
    if ((Get-Item $Global:CMLogFilePath).Length / 1KB -gt $Global:CMLogFileSize)
    {
        $log = $Global:CMLogFilePath
        Remove-Item ($log.Replace(".log", ".lo_"))
        Rename-Item $Global:CMLogFilePath ($log.Replace(".log", ".lo_")) -Force
    }
} 

# Start-CMTraceLog -Path $Global:CMLogFilePath

# Write-CMTraceLog -Message "Info" -Type "Error" -Component "Test"
