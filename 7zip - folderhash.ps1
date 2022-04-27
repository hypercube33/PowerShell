<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
    Determines if we need to download the OS - Example only
    Returns true if we need to download the OS again (rev2)
    SHA-1
#>
########################################################################################################################################################################
# Main Script Variables
$CompanyName            = "Contoso"
$OSV                    = "1909"
$Global:CMLogFilePath   = "C:\ContosoTemp\IPU\$OSV\Logs\folderhash.log"
$DataDir                = "C:\ContosoTemp\IPU\$OSV\GUI\"
########################################################################################################################################################################
# Hash Variables
$ISO    = "C:\ContosoTemp\IPU\$OSV\ISO\CM1005D0"
$O365   = "C:\ContosoTemp\IPU\$OSV\O365\CM1005AC"

# Hash for the folder we are looking for
$ISOTargetHash = "2C2D2E62FCF7143E908CD8A9FA4492E5554DBCD5"
$O365TargetHash = "02CD0C4252A14C6355AF2EADCAF1399677281BE7"

# Files we leave behind once the script runs so we dont run it again
$Pre_ApprovedISO = "C:\ContosoTemp\IPU\$OSV\ISO_Hash.txt"
$Pre_ApprovedO365 = "C:\ContosoTemp\IPU\$OSV\O365_Hash.txt"
########################################################################################################################################################################
# CMTace Functions
########################################################################################################################################################################
# =============================================================================================================
# Core application. ~~
# =============================================================================================================
function Start-CMTraceLog
{
    # Checks for path to log file and creates if it does not exist
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]$Path        
    )

    $indexoflastslash = $Path.lastindexof('\')
    $directory = $Path.substring(0, $indexoflastslash)

    if (!(Test-Path -path $directory))
    {
        New-Item -ItemType Directory -Path $directory
    }
    else
    {
        # Directory Exists, do nothing    
    }
}

# =============================================================================
# Generalized CMTrace Friendly logger - core script function
# =============================================================================
function Write-CMTraceLog
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Message,
            
        [Parameter()]
        [ValidateSet(1, 2, 3)]
        [int]$LogLevel = 1,

        [Parameter()]
        [string]$Component,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Type
    )

    $LogPath = $Global:CMLogFilePath

    Switch ($Type)
    {
        Info { $LogLevel = 1 }
        Warning { $LogLevel = 2 }
        Error { $LogLevel = 3 }
    }

    # Get Date message was triggered
    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"

    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'

    # When used as a module, this gets the line number and position and file of the calling script
    # $RunLocation = "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)"

    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), $Component, $LogLevel
    $Line = $Line -f $LineFormat

    # Write new line in the log file
    try
    {
        Add-Content -Value $Line -Path $LogPath
    }
    catch
    {
        write-host "Could not log to file - file may be locked"
    }

    # Roll log file over at size threshold
    if ((Get-Item $Global:CMLogFilePath).Length / 1KB -gt $Global:CMLogFileSize)
    {
        $log = $Global:CMLogFilePath
        try 
        {
            <#
            The error produced by Remove-Item is considered 'non-terminating', which means that it is ignored by 'try/catch'. To force it to become 'visible' to 'try/catch' use the ErrorAction parameter
            #>
            Remove-Item ($log.Replace(".log", ".lo_")) -ErrorAction Stop
            Rename-Item $Global:CMLogFilePath ($log.Replace(".log", ".lo_")) -Force
        }
        catch
        {
            write-host "Log file roll over failed"
        }
    }
} 

# =============================================================================
# Start the log up
# =============================================================================
Start-CMTraceLog -Path $Global:CMLogFilePath
Write-CMTraceLog -Message "Starting -- folderhash.ps1" -Type "Info" -Component "Main"

# https://gist.github.com/jahands was the inspiration, but 7z is far far faster
Function Get-7zHash
{
    param(
        $Path
    )
    Write-Host "Starting Get-7zHash"
    Write-CMTraceLog -Message "Start - Get Hash Function Using 7zip" -Type "Info" -Component "Get-7zHash"

    Write-Host "   Checking folder: $Path"
    Write-CMTraceLog -Message "   Checking folder: $Path" -Type "Info" -Component "Get-7zHash"

    if(!(Test-Path $Path))
    {
        Write-Host "   Path doesnt exist"
        Write-CMTraceLog -Message "      Path Doesnt Exist >> Aborting" -Type "Warning" -Component "Get-7zHash"

        return $false
    }
    if (!(Test-Path ".\7za.exe"))
    {
        Write-Host "   7zip console application not found"
        Write-CMTraceLog -Message "   7zip console application not found" -Type "Error" -Component "Get-7zHash"

        return $false
    }

    Write-CMTraceLog -Message "      Starting Hash using 7zip for $path" -Type "Info" -Component "Get-7zHash"
    $7zhasher   = &.\7za.exe h -scrcsha1 $Path

    Write-CMTraceLog -Message "      Hash Completed -- running cleanup on output" -Type "Info" -Component "Get-7zHash"
    $Trim       = $7zhasher | Select-Object -Last 8

    #$SHA1       = {$Trim | Select -Last 3 | % {$_ -match "\b([a-fA-F0-9]{40})\b"}};$Matches[0]
    $Trim | Select-Object -Last 3 | ForEach-Object {$_ -match "\b([a-fA-F0-9]{40})\b"} | Out-Null
    $SHA1       = $Matches[0]
    
    Write-CMTraceLog -Message "      Path: $path Hash: $SHA1" -Type "Info" -Component "Get-7zHash"
    return $SHA1
}

Function Get-HashCheck
{
    param(
        $Folder,
        $FolderTargetHash,
        $PreApprovedFilePath
    )

    # /**** Diagnostics ****\
    Write-Host "Get-HashCheck Started"
    Write-Host "   Folder: $Folder"
    Write-Host "   Target hash: $FolderTargetHash"
    Write-Host "   Pre Approved bypass: $PreApprovedFilePath"

    Write-CMTraceLog -Message "Get-HashCheck Started" -Type "Info" -Component "Get-HashCheck"
    Write-CMTraceLog -Message "   Folder: $Folder" -Type "Info" -Component "Get-HashCheck"
    Write-CMTraceLog -Message "   Target hash: $FolderTargetHash" -Type "Info" -Component "Get-HashCheck"
    Write-CMTraceLog -Message "   Pre Approved bypass: $PreApprovedFilePath" -Type "Info" -Component "Get-HashCheck"

    # Check to see if the pre-approved file exists
    if (Test-Path $PreApprovedFilePath)
    {
        Write-Host "   Check for breadcrumbs $PreApprovedFilePath returned True"
        Write-CMTraceLog -Message "   Check for breadcrumbs $PreApprovedFilePath returned True" -Type "Info" -Component "Get-HashCheck"

        # Get the content of the file since it exists
        $FileContent = Get-Content $PreApprovedFilePath

        # Does the content of the pre-approve match our target?
        if($FileContent -eq $FolderTargetHash)
        {
            Write-Host "   Breadcrumb contents matched our target hash -- skipping check to save time"
            Write-CMTraceLog -Message "   Breadcrumb contents matched our target hash -- skipping check to save time" -Type "Info" -Component "Get-HashCheck"
            return $true
        }
        # Content doesnt match - run a test
        else
        {
            Write-Host "   Breadcrumb contents do not match - flagging that we run a 7z hash"
            Write-CMTraceLog -Message "   Breadcrumb contents do not match - flagging that we run a 7z hash" -Type "Info" -Component "Get-HashCheck"

            $GetTheCurrentHash = $True
        }
    }
    else
    {
        Write-Host "   Breadcrumb does not exist - flagging that we run a 7z hash"
        Write-CMTraceLog -Message "   Breadcrumb does not exist - flagging that we run a 7z hash" -Type "Info" -Component "Get-HashCheck"

        $GetTheCurrentHash = $True    
    }

    # Get the File Hash
    if ($GetTheCurrentHash)
    {
        Write-Host "   Run Hash eq True; Getting the current hash"
        Write-CMTraceLog -Message "   Run Hash eq True; Getting the current hash" -Type "Info" -Component "Get-HashCheck"

        $LocalHash = Get-7zHash -Path $Folder

        Write-Host "   Local Hash is: $LocalHash"
        Write-CMTraceLog -Message "   Local Hash is: $LocalHash" -Type "Info" -Component "Get-HashCheck"

        Write-Host "   Begin test to match hashes"
        Write-CMTraceLog -Message "   Begin test to match hashes" -Type "Info" -Component "Get-HashCheck"

        if ($Localhash -eq $FolderTargetHash)
        {
            Write-Host "   Hashes match. Create breadcrumb file"
            Write-CMTraceLog -Message "   Hashes match. Create breadcrumb file" -Type "Info" -Component "Get-HashCheck"

            # Create the pre-approved file so we dont run again
            $LocalHash | Out-File $PreApprovedFilePath

            return $true
        }
        else
        {
            Write-Host "   Hashes DO NOT match."
            Write-CMTraceLog -Message "   Hashes DO NOT match." -Type "Error" -Component "Get-HashCheck"

            return $false
        }
    }
}

Write-CMTraceLog -Message "Begin: Testing hashes" -Type "Info" -Component "Main"
$WinISO = Get-HashCheck -Folder "$ISO" -FolderTargetHash "$ISOTargetHash" -PreApprovedFilePath "$Pre_ApprovedISO"
$O365Data = Get-HashCheck -Folder "$O365" -FolderTargetHash "$O365TargetHash" -PreApprovedFilePath "$Pre_ApprovedO365"

# ========================================================================================================================
# SCCM Stuff
# ========================================================================================================================
Write-CMTraceLog -Message "Begin: SCCM Variables for TS" -Type "Info" -Component "Main"

# Create an object to access the task sequence environment
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment


Write-CMTraceLog -Message "Setting SCCM Variables" -Type "Info" -Component "Main"
$tsenv.Value("O365")    = $WinISO
$tsenv.Value("ISO")     = $O365Data


Write-CMTraceLog -Message "====== End ======" -Type "Info" -Component "Main"