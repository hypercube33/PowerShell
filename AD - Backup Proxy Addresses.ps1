<#
Brian Thorp
2017-11-14

Backs up AD Proxy Addresses to a CSV
#>

# Mode is Export or Import
$Mode = "Export"

$ExportDir = "C:\Temp\"
$ExportFile = "proxyaddresses.csv"



If(!(Test-Path $ExportDir))
{
New-Item -ItemType Directory -Force -Path $ExportDir
}

write-host $Mode 

<# =========================================================================================== #>
#   Export Proxy Address
<# =========================================================================================== #>
if($Mode = "Export")
{
    Get-ADUser -Filter * -Properties proxyaddresses | Select-Object SamAccountName, @{L = "ProxyAddresses"; E = { $_.ProxyAddresses -join ";"}} | Export-Csv -Path c:\temp\proxyaddresses.csv -NoTypeInformation    
}

<# =========================================================================================== #>
#   Import Proxy Address
<# =========================================================================================== #>
if($Mode = "Import")
{
    $Proxys = Import-Csv "C:\temp\proxyaddresses.csv"
    
    ForEach($Proxy in $Proxys)
    {
        $SAM = $Proxy.SamAccountName
        $Proxy =  $Proxy.ProxyAddresses
        Set-ADUser -Identity $SAM -Add @{ProxyAddresses = "$Proxy" -split ";"} 
        echo $SAM
        echo $Proxy
    }
}

