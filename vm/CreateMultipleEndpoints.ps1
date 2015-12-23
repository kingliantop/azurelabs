<#
.SYNOPSIS
       Batch creating multiple endpoints.
       
.DESCRIPTION
       Batch creating multiple endpoints

.NOTES
       Author: Steven Lian
	   Email：stlian@microsoft.com
       Date: 2015/12/14
       Revision: 0.1
#>

#cloud service name
$cloudServiceName = 'mylinuxubuntu'
#virtual machine name
$vmname = 'mylinuxubuntu'
#how many endpoints do you want to create
$NumberOfEndpoints = 100

$VM = Get-AzureVM -ServiceName $cloudServiceName -Name $vmname 

$localPort = 5600

For ($i=0; $i -lt $NumberOfEndpoints; $i++)  
{
    
    $portName = "udp"+ $i
    $pubPort = $localPort
    $VM|Add-AzureEndpoint -Name $portName -Protocol "udp" -PublicPort $pubPort -LocalPort $localPort|Update-AzureVM
    $localPort++    
} 

