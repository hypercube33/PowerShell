<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Some code to cleanup WIM images etc
#>

# Get image imfo including indexes, used below
# Dism /Get-ImageInfo /ImageFile:C:\wim\install.wim

# Extract multi image to single
# imagex /export C:\wim\install.wim 3 C:\wim\install_ent.wim "Windows 10 1803 Enterprise" /compress max

# Mount the WIM file
&cmd /c Dism /Mount-Image /ImageFile:install_ent.wim /Index:1 /MountDir:C:\wim\mount

# Examine WIM for space savings
# &cmd /c Dism /Image:C:\wim\mount /Cleanup-Image /AnalyzeComponentStore

# Cleanup
&cmd /c Dism /Image:C:\wim\mount /Cleanup-Image /StartComponentCleanup

# Further Cleanup
&cmd /c Dism /Image:C:\wim\mount /Cleanup-Image /StartComponentCleanup /ResetBase

# Pack up the WIM File
&cmd /c Dism /Unmount-Image /MountDir:C:\wim\mount /Commit