<#
.NOTES
   ===========================================================================
     Created on:    2022-01-26
     Created by:    Brian Thorp, Bryan Hinze
    ===========================================================================
.Description
   Code to use RegEx to validate an IP Address in a text box
   This was mostly to mess with WinForms Textbox Validation
#>
function Validate-IsIPAddress ([string]$Address)
{
    # Bryan Hinze
    return $Address -match "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
}

$IP = "192.168.10.steve"

Validate-IsIpAddress $IP

# We add two methods? to our textboxes
$textboxIPAddress.add_Validating($textboxIPAddress_Validating)
$textboxIPAddress.add_Validated($textboxIPAddress_Validated)

# Then Two functions for validated and validating 

$textboxIPAddress_Validating=[System.ComponentModel.CancelEventHandler]{
		#TODO: Place custom script here
		$result = -not (Validate-IsIPAddress $textboxIPAddress.Text)
	
		if($result -eq $true)
		{
			$_.Cancel = $true
			$errorprovider1.SetError($this, "Invalid IP address");
		}
	}
	
	$textboxIPAddress_Validated={
		#Pass the calling control and clear error message
		$errorprovider1.SetError($this, "");	
	}