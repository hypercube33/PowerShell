<#
.NOTES
   ===========================================================================
     Created on:    2022-4-27
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Winform Tool to change a machines IP Address to a list of pre-set addresses
#>
#===
$settings = `
@(
    New-Object PSObject -Property @{DisplayName="System Default"; DHCP="$True"; IPAddress="0.0.0.0"; SubnetMask="24"; Gateway="0.0.0.0"; DNS="0.0.0.0"}
    New-Object PSObject -Property @{DisplayName="Demo Settings 1"; DHCP="$False"; IPAddress="192.168.1.2"; SubnetMask="24"; Gateway="0.0.0.0"; DNS="0.0.0.0"}
    New-Object PSObject -Property @{DisplayName="Demo Settings 2"; DHCP="$False"; IPAddress="172.16.1.2"; SubnetMask="24"; Gateway="0.0.0.0"; DNS="0.0.0.0"}
    New-Object PSObject -Property @{DisplayName="Demo Settings 3"; DHCP="$False"; IPAddress="10.0.0.2"; SubnetMask="24"; Gateway="0.0.0.0"; DNS="0.0.0.0"}
)

# Get the Ethernet Adapter
$adapter = Get-NetAdapter | Where-Object { $_.Name -eq "Ethernet" }


function Get-CurrentConfig
{
    param(
        $Adapter
    )
    # # Write-Host "==============================================="
    # Write-Host "Function Get-CurrentConfig"
    # Write-Host "==============================================="

    $Interface       = $adapter.InterfaceDescription # $CurrentSettings.InterfaceDescription

    # Does the adapter exist?
    $AdapterReady = ((Get-NetIPConfiguration).InterfaceIndex) -contains $adapter.ifIndex # 800ms
    if ($AdapterReady)
    {
        $AdapterDetails         = ($adapter | Get-NetIPConfiguration)
        $IP                     = $AdapterDetails.IPv4Address.IPAddress
        $CIDR                   = $AdapterDetails.IPv4Address.PrefixLength
        $Gateway                = $AdapterDetails.IPv4DefaultGateway.NextHop

        # Fix for DNS not having a value - test and ignore otherwise
        $PreDNS = $AdapterDetails.DNSServer.ServerAddresses
        if (!([string]::IsNullOrEmpty($PreDNS))) # if this is null or empty then we abort
        {
            $DNS = $PreDNS[1] # Select only the first one, Primary DNS
        }


        $xDHCP                   = ($adapter | Get-NetIPInterface -ifIndex $adapter.ifindex).DHCP
        
        # Write-Host "DNS: $DNS"
        $AllDNS = $AdapterDetails.DNSServer.ServerAddresses
        # Write-Host "All DNS: $ALLDns"

        if ($xDHCP -like "Enabled") { $dhcp = $true}
        if ($xDHCP -like "Disabled") { $dhcp = $false}
    }
    if (!$AdapterReady)
    {
        # Show Error Message~
        # Write-Host "Error - Adapter is not ready" -ForegroundColor "Red"
        $StatusTextBox.AppendText("Error with adapter`r`n")
    }
    if ($AdapterReady)
    {
        # Write-Host "Adapter is determined to be ready, loading values to write to GUI" -ForegroundColor "Green"
        <#
        $CurrentIP              = $StartCurrent.IP
        $CurrentCIDR            = $StartCurrent.CIDR
        $CurrentGateway         = $StartCurrent.Gateway
        $CurrentDNS             = $StartCurrent.DNS
        $CurrentDHCP            = $StartCurrent.DHCP

        # Write-Host ""
        # Write-Host ""
        # Write-Host ""
        # Write-Host ""
        # Write-Host ""
        #>
        # Write-Host "Updating GUI with current settings"

        $CurrentDHCPLabel.Text              = "$DHCP"
        $CurrentIPLabel.Text                = "$IP"
        $CurrentCIDRLabel.Text              = "$CIDR"
        $CurrentGatewayLabel.Text           = "$Gateway"
        $CurrentDNSLabel.Text               = "$DNS"
    
        #$results = @($DHCP,$IP,$CIDR,$Gateway,$DNS)
        # Write-Host "Ready" -ForegroundColor "Green"
        $StatusTextBox.AppendText("Ready`r`n")
    }

    $results = New-Object PsObject -Property @{AdapterReady=$adapterready; Interface = $Interface; DHCP=$DHCP; IP=$IP; CIDR=$CIDR; Gateway=$Gateway;DNS=$DNS}
    Return $results
}

# Get-CurrentConfig -Adapter $Adapter



# https://stackoverflow.com/questions/27690918/array-find-and-indexof-for-multiple-elements-that-are-exactly-the-same-object
function get-IndicesOf($Array, $Value) 
{
    $i = 0
    foreach ($el in $Array)
    { 
      if ($el -eq $Value) { $i } 
      ++$i
    }
}

function Set-Ethernet
{
    param(
        $DHCP,
        $adapter,
        $IP,
        $MaskBits,
        $Gateway,
        $DNS
    )
    # Write-Host "==============================================="
    # Write-Host "Function - Set-Ethernet"
    # Write-Host "==============================================="
    write-host "DHCP is $dhcp"
    $type = $dhcp.gettype()
    # Write-Host "DHCP is $type"

    if ($type -like "string")
    {
        if ($DHCP -like "True") {$dhcp = $true}
        if ($DHCP -like "False") {$dhcp = $false}
    }

    $IPType = "IPv4"
    # Retrieve the network adapter that you want to configure
    
    if ($dhcp -eq $false)
    {
        write-host "DHCP is false so we'll apply IP configuration"
        # Remove any existing IP, gateway from our ipv4 adapter
        If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress)
        {
            $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
        }
        If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway)
        {
            $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
        }

        # Write-Host "Applying IP Configuration..."
        $StatusTextBox.AppendText("Applying configuration...`r`n")

        # Check for null Gateway
        if ($Gateway -eq "0.0.0.0")
        {
            $adapter | New-NetIPAddress `
            -AddressFamily $IPType `
            -IPAddress $IP `
            -PrefixLength $MaskBits `
            #-DefaultGateway $Gateway
        }
        if ($Gateway -ne "0.0.0.0")
        {
                $adapter | New-NetIPAddress `
            -AddressFamily $IPType `
            -IPAddress $IP `
            -PrefixLength $MaskBits `
            -DefaultGateway $Gateway
        }
        # Configure the IP address and default gateway


        # Configure the DNS client server IP addresses
        $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
    }

    if ($dhcp)
    {
        write-host "DHCP is true so we'll clear and set to DHCP"
        # Remove existing gateway
        If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway)
        {
            # Note - this will sometimes throw an error
            $adapter | Remove-NetRoute -Confirm:$false
        }
    
        # Enable DHCP
        $adapter | Set-NetIPInterface -DHCP Enabled
    
        # Configure the DNS Servers automatically
        $adapter | Set-DnsClientServerAddress -ResetServerAddresses
    }

}

#region Form
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$Form1                  = New-Object System.Windows.Forms.Form
$Form1.ClientSize       = New-Object System.Drawing.Size(400, 220)
$form1.topmost          = $true
$Form1.FormBorderStyle  = "Fixed3D"
$Form1.MaximizeBox      = $False
$Form1.Text            = "Contoso IP Changer v1.05"
#endregion Form

#region Functions
Function Get-Values
{
    # Write-Host "==============================================="
    # Write-Host "Function - Get-Values"
    # Write-Host "==============================================="
    If ($ComboBox1.SelectedItem -lt 0)
    {
        $Selected = "No selection was made"
        Write-host $Selected -ForegroundColor Red
    }
    Else
    {
        $Selected = $ComboBox1.SelectedItem.ToString()
        Write-host "$Selected chosen" -ForegroundColor Green
        
        # Write-Host "Breaking apart values for use..."
        # What is selected?
        $DisplayName = ($Settings.DisplayName)
        $SelectedIndex = get-IndicesOf ($DisplayName) $Selected
        # Write-Host $Selected
        # Write-Host "Index: $SelectedIndex"
        # Write-Host "DisplayName: $DisplayName"

        $LoadedDHCP     = $Settings.DHCP[$SelectedIndex]
        $LoadedIP       = $Settings.IPAddress[$SelectedIndex]
        $LoadedCIDR     = $Settings.SubnetMask[$SelectedIndex]
        $LoadedGateway  = $Settings.Gateway[$SelectedIndex]
        $LoadedDNS      = $Settings.DNS[$SelectedIndex]

        $LoadedDHCPLabel.Text           = "$LoadedDHCP"
        $LoadedIPLabel.Text             = "$LoadedIP"
        $LoadedCIDRLabel.Text           = "$LoadedCIDR"
        $LoadedGatewayLabel.Text        = "$LoadedGateway"
        $LoadedDNSLabel.Text            = "$LoadedDNS"
    }
    write-host $LoadedDHCP,$LoadedIP,$LoadedCIDR,$LoadedGateway,$LoadedDNS
    # $results = New-Object PsObject -Property @{DHCP=$LoadedDHCP;IP=$LoadedIP;CIDR=$LoadedCIDR;Gateway=$LoadedGateway;DNS=$LoadedDNS}
    $results = @($LoadedDHCP,$LoadedIP,$LoadedCIDR,$LoadedGateway,$LoadedDNS)

    # Enable Apply Button
    $ApplyButton1.Enabled = $True
    # Write-Host "Ready" -ForegroundColor "Green"
    $StatusTextBox.AppendText("Ready`r`n")

    $Global:Load = $results
    Return $results
}

Function Compare-IPSettings
{
    param(
        $CurrentSettings,   # Current Settings
        $TargetSettings     # Target Settings
    )

    # Write-Host "==============================================="
    # Write-Host "Function - Compare-IPSettings"
    # Write-Host "==============================================="
    # Write-Host "Current Settings: $CurrentSettings"
    # Write-Host "Target Settings: $TargetSettings"

    $TargetBlank  = [string]::IsNullOrEmpty($TargetSettings)
    $CurrentBlank = [string]::IsNullOrEmpty($CurrentSettings)

    # Write-Host "Target is blank? $TargetBlank"
    # Write-Host "Current is blank? $CurrentBlank"

    # If one or the other is blank we'll just eject
    if (!$TargetBlank -and !$CurrentBlank)
    {
        # Write-Host "Target and Current settings are not blank..."
        $trigger = $TargetSettings[0]
        # Write-Host "Target DHCP? $trigger"
        # If the target is DHCP we'll ignore everything else and just compare these
        if($trigger -like "True") # TODO
        {
            # Write-Host "Target settings are DHCP"
            $Result = $TargetSettings[0] -eq $CurrentSettings[0]
        }
        else
        {

                # Write-Host "-----------------------------------------------"
                $CDHCP      = $CurrentSettings[0]
                $CIP        = $CurrentSettings[1]
                $CCIDR      = $CurrentSettings[2]
                $CGateway   = $CurrentSettings[3]
                $CDNS       = $CurrentSettings[4]

                # Write-Host "Current Setting: DHCP is $CDHCP"
                # Write-Host "Current Setting: IP is $CIP"
                # Write-Host "Current Setting: Subnet is $CCIDR"
                # Write-Host "Current Setting: Gateway is $CGateway"
                # Write-Host "Current Setting: DNS is $CDNS"

                # Fix wierd null stuff
                if ([string]::IsNullOrEmpty($CGateway)) {$CGateway = "0.0.0.0"}
                if ($CDNS -eq ".") {$CDNS = "0.0.0.0"}
                # Write-Host "Corrected Values:"
                # Write-Host "Current Setting: Gateway is $CGateway"
                # Write-Host "Current Setting: DNS is $CDNS"

                $UpdatedCurrent = $CDHCP, $CIP, $CCIDR, $CGateway, $CDNS

                # Write-Host "-----------------------------------------------"
                $TDHCP      = $TargetSettings[0]
                $TIP        = $TargetSettings[1]
                $TCIDR      = $TargetSettings[2]
                $TGateway   = $TargetSettings[3]
                $TDNS       = $TargetSettings[4]

                # Write-Host "Target Setting: DHCP is $TDHCP"
                # Write-Host "Target Setting: IP is $TIP"
                # Write-Host "Target Setting: Subnet is $TCIDR"
                # Write-Host "Target Setting: Gateway is $TGateway"
                # Write-Host "Target Setting: DNS is $TDNS"

                $Compare = Compare-Object -ReferenceObject $TargetSettings -DifferenceObject $UpdatedCurrent
    
                # Compare Object only shows what is different so its blank if its the same
                $Result = [string]::IsNullOrEmpty($Compare)
        }
        if ($result) {$StatusTextBox.AppendText("Successfully Applied Settings!`r`n")}
        return $result
    }
 
}

Function Set-Values
{
    param(
        $Values,
        $Adapter
    )
    # Write-Host "==============================================="
    # Write-Host "Function - Set-Values"
    # Write-Host "==============================================="
    # Write-Host "Vales are: $Values"
    # Write-Host "Adapter is: $Adapter"
    # Rip values from array
    $DHCP       = $Values[0]
    $IP         = $Values[1]
    $CIDR       = $Values[2]
    $Gateway    = $Values[3]
    $DNS        = $Values[4]

    # Write-Host $DHCP
    # Write-Host $IP
    # Write-Host $CIDR
    # Write-Host $Gateway
    # Write-Host $DNS

    #Display Applying...

    # Set the new values
    Set-Ethernet -adapter $Adapter -DHCP $DHCP -IP $IP -MaskBits $CIDR -Gateway $Gateway -DNS $DNS

    # Get the current values -> Function?
    $StageUpdatedValues = Get-CurrentConfig -Adapter $Adapter
    $UpdatedDHCP        = $StageUpdatedValues.DHCP
    $UpdatedIP          = $StageUpdatedValues.IP
    $UpdatedCIDR        = $StageUpdatedValues.CIDR
    $UpdatedGatway      = $StageUpdatedValues.Gateway
    $UpdatedDNS         = $StageUpdatedValues.DNS
    $UpdatedInterface   = $StageUpdatedValues.Interface
    $UpdatedAdapterRdy  = $StageUpdatedValues.AdapterReady
    $UpdatedValues = @($UpdatedDHCP,$UpdatedIP,$UpdatedCIDR,$UpdatedGatway,$UpdatedDNS)
    

    # Compare current to what we wanted set
    $Compare = Compare-IPSettings -CurrentSettings $UpdatedValues -TargetSettings $Load
    Write-host "Set is: $Compare"

    # If the compare is good, show Successful | Else Failed
    # Write-Host "Succesful" -ForegroundColor "Green"

    # Update 
}


#endregion Functions

#region Dropdown
$comboBox1                          = New-Object System.Windows.Forms.ComboBox
$comboBox1.Location                 = New-Object System.Drawing.Point(10, 8)
$comboBox1.Size                     = New-Object System.Drawing.Size(180, 20)

# Load the  settings into the combo box dynamically
ForEach($item in $settings)
{
    $box = $item.DisplayName
    $comboBox1.Items.add("$box")
}
$ComboBox1.DropDownStyle    = [System.Windows.Forms.ComboBoxStyle]::DropDownList;
$ComboBox1.SelectedIndex    = 0
$comboBox1.add_SelectedIndexChanged({Get-Values})

$Form1.Controls.Add($comboBox1)
#endregion Dropdown

#region Buttons
#region Load Button1
# $LoadButton1                        = New-Object System.Windows.Forms.Button
# $LoadButton1.Size                   = New-Object System.Drawing.Size(70, 24)
# $LoadButton1.Location               = New-Object System.Drawing.Size(180, 6)
# $LoadButton1.Text                   = "Load"
# $LoadButton1.Add_Click( { (Get-Values) }) #Test-Something
# $Form1.Controls.Add($LoadButton1)
#endregion Load Button1

$ApplyButton1                       = New-Object System.Windows.Forms.Button
$ApplyButton1.Size                  = New-Object System.Drawing.Size(220, 24)
$ApplyButton1.Location              = New-Object System.Drawing.Size(75, 130)
$ApplyButton1.Text                  = "Apply >>"
$ApplyButton1.Add_Click({ Set-Values -Values $Global:Load -Adapter $adapter; Get-CurrentConfig -Adapter $Adapter })
$ApplyButton1.Enabled = $False
$Form1.Controls.Add($ApplyButton1)
#endregion Buttons

#region Labels
$EthLabel                          = new-object System.Windows.Forms.Label
$EthLabel.Location                 = new-object System.Drawing.Size(10, 32) 
$EthLabel.size                     = new-object System.Drawing.Size(300, 13) 
$EthLabel.Text                     = "Current Interface: $CurrentInterface"
$Form1.Controls.Add($EthLabel)


$DHCPLabel                          = new-object System.Windows.Forms.Label
$DHCPLabel.Location                 = new-object System.Drawing.Size(12, 64) 
$DHCPLabel.size                     = new-object System.Drawing.Size(108, 13) 
$DHCPLabel.Text                     = "DHCP:"
$Form1.Controls.Add($DHCPLabel)

$IPLabel                            = new-object System.Windows.Forms.Label
$IPLabel.Location                   = new-object System.Drawing.Size(12, 77) 
$IPLabel.size                       = new-object System.Drawing.Size(108, 13) 
$IPLabel.Text                       = "IP Address:"
$Form1.Controls.Add($IPLabel)

$CIDRLabel                          = new-object System.Windows.Forms.Label
$CIDRLabel.Location                 = new-object System.Drawing.Size(12, 90) 
$CIDRLabel.size                     = new-object System.Drawing.Size(108, 13)  
$CIDRLabel.Text                     = "Subnet Mask:"
$Form1.Controls.Add($CIDRLabel)

$GatewayLabel                       = new-object System.Windows.Forms.Label
$GatewayLabel.Location              = new-object System.Drawing.Size(12, 103) 
$GatewayLabel.size                  = new-object System.Drawing.Size(108, 13)  
$GatewayLabel.Text                  = "Gateway:"
$Form1.Controls.Add($GatewayLabel)

$DNSLabel                           = new-object System.Windows.Forms.Label
$DNSLabel.Location                  = new-object System.Drawing.Size(12, 116) 
$DNSLabel.size                      = new-object System.Drawing.Size(108, 13) 
$DNSLabel.Text                      = "DNS:"
$Form1.Controls.Add($DNSLabel)

$LoadedLabel                        = new-object System.Windows.Forms.Label
$LoadedLabel.Location               = new-object System.Drawing.Size(130, 50) 
$LoadedLabel.size                   = new-object System.Drawing.Size(108, 13) 
$LoadedLabel.Text                   = "Loaded Settings"
$Form1.Controls.Add($LoadedLabel)

$CurrentLabel                       = new-object System.Windows.Forms.Label
$CurrentLabel.Location              = new-object System.Drawing.Size(270, 50) 
$CurrentLabel.size                  = new-object System.Drawing.Size(108, 13) 
$CurrentLabel.Text                  = "Current Settings"
$Form1.Controls.Add($CurrentLabel)

# Labels for Current Adapter Settings
$CurrentDHCPLabel                   = new-object System.Windows.Forms.Label
$CurrentDHCPLabel.Location          = new-object System.Drawing.Size(270, 64) 
$CurrentDHCPLabel.size              = new-object System.Drawing.Size(108, 13) 
#$CurrentDHCPLabel.Text              = "$CurrentDHCP"
$Form1.Controls.Add($CurrentDHCPLabel)

$CurrentIPLabel                     = new-object System.Windows.Forms.Label
$CurrentIPLabel.Location            = new-object System.Drawing.Size(270, 77) 
$CurrentIPLabel.size                = new-object System.Drawing.Size(108, 13) 
#$CurrentIPLabel.Text                = "$CurrentIP"
$Form1.Controls.Add($CurrentIPLabel)

$CurrentCIDRLabel                   = new-object System.Windows.Forms.Label
$CurrentCIDRLabel.Location          = new-object System.Drawing.Size(270, 90) 
$CurrentCIDRLabel.size              = new-object System.Drawing.Size(108, 13) 
#$CurrentCIDRLabel.Text              = "$CurrentCIDR"
$Form1.Controls.Add($CurrentCIDRLabel)

$CurrentGatewayLabel                = new-object System.Windows.Forms.Label
$CurrentGatewayLabel.Location       = new-object System.Drawing.Size(270, 103) 
$CurrentGatewayLabel.size           = new-object System.Drawing.Size(108, 13) 
#$CurrentGatewayLabel.Text           = "$CurrentGateway"
$Form1.Controls.Add($CurrentGatewayLabel)

$CurrentDNSLabel                    = new-object System.Windows.Forms.Label
$CurrentDNSLabel.Location           = new-object System.Drawing.Size(270, 116) 
$CurrentDNSLabel.size               = new-object System.Drawing.Size(108, 13) 
#$CurrentDNSLabel.Text               = "$CurrentDNS"
$Form1.Controls.Add($CurrentDNSLabel)

# Labels for Loaded Adapter Settings
$LoadedDHCPLabel                    = new-object System.Windows.Forms.Label
$LoadedDHCPLabel.Location           = new-object System.Drawing.Size(130, 64) 
$LoadedDHCPLabel.size               = new-object System.Drawing.Size(108, 13) 
$LoadedDHCPLabel.Text               = "$LoadedDHCP"
$Form1.Controls.Add($LoadedDHCPLabel)

$LoadedIPLabel                      = new-object System.Windows.Forms.Label
$LoadedIPLabel.Location             = new-object System.Drawing.Size(130, 77) 
$LoadedIPLabel.size                 = new-object System.Drawing.Size(108, 13) 
$LoadedIPLabel.Text                 = "$LoadedIP"
$Form1.Controls.Add($LoadedIPLabel)    

$LoadedCIDRLabel                    = new-object System.Windows.Forms.Label
$LoadedCIDRLabel.Location           = new-object System.Drawing.Size(130, 90) 
$LoadedCIDRLabel.size               = new-object System.Drawing.Size(108, 13) 
$LoadedCIDRLabel.Text               = "$LoadedCIDR"
$Form1.Controls.Add($LoadedCIDRLabel)

$LoadedGatewayLabel                 = new-object System.Windows.Forms.Label
$LoadedGatewayLabel.Location        = new-object System.Drawing.Size(130, 103) 
$LoadedGatewayLabel.size            = new-object System.Drawing.Size(108, 13) 
$LoadedGatewayLabel.Text            = "$LoadedGateway"
$Form1.Controls.Add($LoadedGatewayLabel)

$LoadedDNSLabel                     = new-object System.Windows.Forms.Label
$LoadedDNSLabel.Location            = new-object System.Drawing.Size(130, 116) 
$LoadedDNSLabel.size                = new-object System.Drawing.Size(108, 13) 
$LoadedDNSLabel.Text                = "$LoadedDNS"
$Form1.Controls.Add($LoadedDNSLabel)

$StatusTextBox                        = New-Object System.Windows.Forms.TextBox
$StatusTextBox.Location               = New-Object System.Drawing.Size(75, 160)
$StatusTextBox.Size                   = New-Object System.Drawing.Size(300, 50)
$StatusTextBox.Enabled                = $False
$StatusTextBox.Multiline              = $True
$StatusTextBox.AppendText("(Startup)`r`n")
$Form1.Controls.Add($StatusTextBox)
#endregion Labels

# =======================================================================
# Statup Main Code
# =======================================================================
# Run start - grab the current data
$StartCurrent           = Get-CurrentConfig -Adapter $Adapter

# Get the adapter settings - Name
$CurrentInterface       = $StartCurrent.Interface

# Does the adapter exist?
$AdapterReady           = $StartCurrent.AdapterReady

# Write-Host "Main: Adapter is ready? $AdapterReady"

# These are updated after the GUI loads...TODO - fix this
<#
if ($AdapterReady)
{
    # Write-Host "Adapter is determined to be ready, loading values to write to GUI"
    $CurrentIP              = $StartCurrent.IP
    $CurrentCIDR            = $StartCurrent.CIDR
    $CurrentGateway         = $StartCurrent.Gateway
    $CurrentDNS             = $StartCurrent.DNS
    $CurrentDHCP            = $StartCurrent.DHCP
}
if (!$AdapterReady)
{
    # Write-Host "Error - Adapter is not ready" -ForegroundColor "Red"
    $StatusTextBox.AppendText("Error with adapter - not ready`r`n")

    # TODO - lock the app up?
}
#>
# =======================================================================

# Draw the form - should be last in code~
[void]$form1.showdialog()

