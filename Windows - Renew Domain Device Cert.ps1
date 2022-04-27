<#
.NOTES
   ===========================================================================
     Created on:    2022-03-16
     Created by:    Brian Thorp
    ===========================================================================
.Description
   Renew Domain Certs on a machine. I didnt write this code, but I cant figure out where I got it :(
#>
$Computer = $env:COMPUTERNAME
$CN = "$Computer.contoso.com"

$cert = (ls Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=$CN" })[0]
&certreq @('-Enroll', '-machine', '-q', '-cert', $cert.SerialNumber, 'Renew', 'ReuseKeys')