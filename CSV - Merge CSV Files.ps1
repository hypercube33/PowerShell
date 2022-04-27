<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Grabs all csv files in a folder path and combines them
#>
Get-ChildItem -Filter *.csv -Path C:\Scripts\CSVFiles | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv C:\Scripts\CSVFiles\CombinedFile.csv -NoTypeInformation -Append