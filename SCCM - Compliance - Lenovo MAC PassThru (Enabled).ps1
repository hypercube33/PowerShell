# https://gallery.technet.microsoft.com/scriptcenter/View-BIOS-Settings-on-e294bafa

function Get-LenovoBIOSSetting
{ 
    Param( 
        [Parameter(ValueFromPipeline=$True,valuefrompipelinebypropertyname=$True)] 
        [Alias('Name')] 
        $ComputerName = $Env:ComputerName 
        ) 
     
    $WMI = Get-WmiObject -class Lenovo_BiosSetting -namespace root\wmi -ComputerName $ComputerName 
     
    $BIOSsettings = New-Object PSObject 
    $BIOSsettings | Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $WMI[0].__Server 
     
    $WMI | ForEach{ 
        if($_.CurrentSetting -ne ""){ 
            $Setting = $_.CurrentSetting -split ',' 
            $BIOSsettings | Add-Member -MemberType NoteProperty -Name $Setting[0] -Value $Setting[1] -Force 
            } 
        } 
    $BIOSSettings
}

$BIOS = Get-LenovoBIOSSetting

$MACPass = $BIOS.MACAddressPassThrough

$MACPass