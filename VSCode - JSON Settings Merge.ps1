<#
.NOTES
   ===========================================================================
     Created on:    2020-10-26
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Code to run during VSCode deployment to merge settings with the users existing~
#>
# User Preferences to all users~ 
$UserPrefs = "$DirFiles\settings.json"

$baddate = (Get-Date 2019-03-08) # Broken File Date

# Extensions to seed for all users
# $Extensions = "$DirSupportFiles\extensions"

# Cycle through user folders and seed everything
$users = Get-ChildItem -Path "C:\Users\"

# User Paths to Exclude
$exclusions = "Public","defaultuser0", "ADMINI~1"

# Loop to seed everything
ForEach($user in $users)
{
	# True if User is not in Exclusion List
	if ($exclusions -notcontains [system.string]$user)
	{
		# Make .vscode file in root of user home folder
		# &cmd.exe /c md "C:\Users\$user\.vscode\extensions"

		# Copy Extensions
		# Copy-File -Path "$Extensions\*.*" -Destination "C:\Users\$user\.vscode\extensions"
		
		# User Profile - create if it doesnt exist
		if (!(Test-Path "C:\Users\$user\AppData\Roaming\Code\User"))
		{
			&cmd.exe /c md "C:\Users\$user\AppData\Roaming\Code\User"
		}
		

		# Try to not overwrite users settings
		$Settings = "C:\Users\$user\AppData\Roaming\Code\User\settings.json"

		# If there are exisitng users settings we'll try to merge them
		if (Test-Path $Settings)
		{
			# Look for and remove broken JSON file
			$ExistingDate = (Get-ChildItem $Settings).LastWriteTime#.CreationTime

			# Is the folder equal to or newer than when we started pushing this out?
			if ( $ExistingDate -eq $baddate )
			{
				Remove-Item $Settings -Force
				Copy-File -Path "$userprefs" -Destination $Settings
			}
			# Else we'll just merge our stuff to theirs
			else
			{
				# Copy Settings.json
				#Copy-File -Path "$userprefs" -Destination $Settings

				# Load the users settings
				$json1 = Get-Content -Path "$Settings" -Raw | ConvertFrom-Json

				# Load our desired settings
				$json2 = Get-Content -Path "$UserPrefs" -Raw | ConvertFrom-Json

				function Start-JSONMerge ($target, $source)
				{
					$source.psobject.Properties | % `
					{
						if ($_.TypeNameOfValue -eq 'System.Management.Automation.PSCustomObject' -and $target."$($_.Name)" )
						{
							merge $target."$($_.Name)" $_.Value
						}
						else
						{
							$target | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value -Force
						}
					}
				}

				# Combine the Settings
				Start-JSONMerge $Json1 $Json2

				# Output the new settings
				$Json1 | ConvertTo-JSON | Out-File -FilePath $Settings -Force
			}	
		}
		else                        
		{
			Copy-File -Path "$userprefs" -Destination $Settings
		}
	}
}