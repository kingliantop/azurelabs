<#
.SYNOPSIS
       Create multiple NICs for one VM
       
.DESCRIPTION
       Batch creating multiple endpoints

.NOTES
       Author: Steven Lian
	   Email：stlian@microsoft.com
       Date: 2015/3/14
       Revision: 0.1
#>


Set-AzureSubscription -SubscriptionId XXXXX -CurrentStorageAccountName  myvmstorage

$image=Get-AzureVMImage | where {$_.ImageName -like "*Ubuntu-14_04_1-LTS-amd64-server-20150123*"}

$adminusername="azureuser"
$adminpassword="Mylinux123!"

$Subnet1Name="WebNet"
$Subnet2Name="AppNet"
$Subnet3Name="MNet"


$NIC1IP="10.0.2.18"
$NIC2IP="10.0.1.18" 
$NIC3IP="10.0.3.18" 

$vm = New-AzureVMConfig -Name "MNICVM" -InstanceSize "ExtraLarge" -Image $image.ImageName

Add-AzureProvisioningConfig -VM $vm  -Linux -LinuxUser $adminusername -Password $adminpassword

#set default IP address

Set-AzureSubnet -SubnetNames $Subnet1Name -VM $vm
Set-AzureStaticVNetIP -IPAddress $NIC1IP -VM $vm

Add-AzureNetworkInterfaceConfig -Name "NIC2" -SubnetName $Subnet2Name -StaticVNetIPAddress $NIC2IP -VM $vm
Add-AzureNetworkInterfaceConfig -Name "NIC3" -SubnetName $Subnet3Name -StaticVNetIPAddress $NIC3IP -VM $vm

New-AzureVM -ServiceName "mnicdemoservice" -VNetName "mnicdemo" -VM $vm  -Location 'China East'





