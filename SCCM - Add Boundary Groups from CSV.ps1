<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Creates a new boundary group from a CSV file
#>
$BoundaryGroupName = "Happy little accidents"

# Get group ID
$GroupID = (Get-CMBoundaryGroup -Name "$BoundaryGroupName").GroupID

$boundaries = Import-CSV -Path "C:\src\boundaries.csv"

foreach ($Boundary in $Boundaries)
{
    $Start = $Boundary.Start
    $End = $Boundary.End
    $BoundaryName = "KTVPN $Start/24"

    New-CMBoundary -DisplayName "$BoundaryName" -BoundaryType IPRange -Value "$Start-$End"

    Add-CMBoundaryToGroup -BoundaryGroupID "$GroupID" -BoundaryName "$BoundaryName"
}