<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Grabs all csv files in a folder path and combines them + adds a column for what csv file it came from
#>
## Add the file name to the CSV
cd "\\sccm.contoso.com\sources\logs\MappedDrives"
$CSVFiles = Get-ChildItem -Filter *.csv | Select-Object -ExpandProperty FullName

ForEach ($CSV in $CSVFiles)
{
    $Filename = Split-Path -Path $CSV -Leaf

    Import-CSV $Filename | Select-Object *,@{Name='FileName';Expression={"$Filename"}} | Export-Csv "C:\ContosoTemp\MappedDrives\$Filename" -NoTypeInformation
}

## Combine the CSVs
cd "C:\ContosoTemp\MappedDrives\"
Get-ChildItem -Filter *.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv "C:\ContosoTemp\mappeddrivescsv\combinedcsvs.csv" -NoTypeInformation -Append
