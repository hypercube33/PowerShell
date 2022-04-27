
<#
.NOTES
   ===========================================================================
     Created on:    2022-04-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Lenovo Model Lookup Demo
#>
Function Get-CMDeviceCS
{
    Param(
        $ResourceID,

        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        $SiteName,
        
        [Parameter(Mandatory = $true)]
        $SiteServer
    )

    if (!($ResourceID))
    {
        $ResourceID = (Get-CMDevice -Name $ResourceName).ResourceID
    }

    try
    {
        $Return = Get-WmiObject -ComputerName $SiteServer -Namespace "root\SMS\site_$SiteName" -Class SMS_G_System_COMPUTER_SYSTEM -Filter "ResourceID = '$ResourceID'" -ErrorAction stop
    }
    catch
    {
        write-warning $_
    }

    return $Return
}


function Get-LenovoModelName
{
    Param(
        [Parameter(Mandatory = $true)]
        $CSPModel
    )

    # Lenovo Model Lookup
    Switch -wildcard (($Device.Model).SubString(0,4))
    {
        "20LD*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 3"}
        "20LE*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 3"}
        "20LF*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 3"}
        "20LG*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 3"}
        "81CG*" {$LenovoModel = "Lenovo Miix 520"}
        "20JD*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 2"}
        "20JE*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 2"}
        "20JF*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 2"}
        "20JG*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 2"}
        "20FQ*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 1"}
        "20FR*" {$LenovoModel = "Lenovo ThinkPad X1 Yoga Gen 1"}
        "20JB*" {$LenovoModel = "Lenovo ThinkPad X1 Tablet Gen 2"}
        "20JC*" {$LenovoModel = "Lenovo ThinkPad X1 Tablet Gen 2"}
        "20GG*" {$LenovoModel = "Lenovo ThinkPad X1 Tablet Gen 1"}
        "20GH*" {$LenovoModel = "Lenovo ThinkPad X1 Tablet Gen 1"}
        "20FB*" {$LenovoModel = "Lenovo ThinkPad X1 Carbon 4th"}
        "20FC*" {$LenovoModel = "Lenovo ThinkPad X1 Carbon 4th"}
        "20KJ*" {$LenovoModel = "Lenovo ThinkPad X1 Tablet Gen 3"}
        "20KK*" {$LenovoModel = "Lenovo ThinkPad X1 Tablet Gen 3"}
        "20FH*" {$LenovoModel = "Lenovo ThinkPad T560"}
        "20FJ*" {$LenovoModel = "Lenovo ThinkPad T560"}
        "20BF*" {$LenovoModel = "Lenovo ThinkPad T540p"}
        "20BE*" {$LenovoModel = "Lenovo ThinkPad T540p"}
        "20MU*" {$LenovoModel = "Lenovo ThinkPad A485"}
        "20MV*" {$LenovoModel = "Lenovo ThinkPad A485"}
        "20L5*" {$LenovoModel = "Lenovo ThinkPad T480"}
        "20L6*" {$LenovoModel = "Lenovo ThinkPad T480"}
        "20JM*" {$LenovoModel = "Lenovo ThinkPad T470 SkyLake"}
        "20JN*" {$LenovoModel = "Lenovo ThinkPad T470 SkyLake"}
        "20F9*" {$LenovoModel = "Lenovo ThinkPad T460s"}
        "20FA*" {$LenovoModel = "Lenovo ThinkPad T460s"}
        "20M9*" {$LenovoModel = "Lenovo ThinkPad P52"}
        "20MA*" {$LenovoModel = "Lenovo ThinkPad P52"}
        "20HH*" {$LenovoModel = "Lenovo ThinkPad P51"}
        "20HJ*" {$LenovoModel = "Lenovo ThinkPad P51"}
        "20FK*" {$LenovoModel = "Lenovo ThinkPad P50s"}
        "20FL*" {$LenovoModel = "Lenovo ThinkPad P50s"}
        "20EN*" {$LenovoModel = "Lenovo ThinkPad P50"}
        "20EQ*" {$LenovoModel = "Lenovo ThinkPad P50"}
        "20GQ*" {$LenovoModel = "Lenovo ThinkPad P40 Yoga"}
        "20GR*" {$LenovoModel = "Lenovo ThinkPad P40 Yoga"}
        "20M7*" {$LenovoModel = "Lenovo ThinkPad L380 Yoga"}
        "20M8*" {$LenovoModel = "Lenovo ThinkPad L380 Yoga"}
        "20M5*" {$LenovoModel = "Lenovo ThinkPad L380"}
        "20M6*" {$LenovoModel = "Lenovo ThinkPad L380"}
        "10MQ*" {$LenovoModel = "Lenovo ThinkCentre M710q"}
        "10MR*" {$LenovoModel = "Lenovo ThinkCentre M710q"}
    }

    return $LenovoModel
}

function Get-NameModel
{
    Param(
        [Parameter(Mandatory = $true)]
        $CSPModel
    )
    
    # Pass to Lenovo Model Case Select and if its not matching pass through
    $CasePass = Get-LenovoModelName -CSPModel $CSPModel

    if ($null -eq $CasePass)
    {
        return $CSPModel
    }
    else
    {
        return $CasePass    
    }
}

# Get Device CS Product from SCCM
$Device = Get-CMDeviceCS -ResourceName "DemoMachine" -SiteName "CM1" -SiteServer "sccm.contoso.com"

# Process through filter to get name if its a lenovo (or not)
Get-NameModel -CSPModel $Device.Model