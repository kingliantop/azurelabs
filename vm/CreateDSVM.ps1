<#
.SYNOPSIS
       Create DS VMs which use Premium Storage

       
.DESCRIPTION
       Create DS VMs which use Premium Storage
       Premium Storage is OLY avaliable in China East

.NOTES
       Author: Steven Lian
	   Email:  stlian@microsoft.com
       Date: 2015/12/23
       Revision: 0.1
#>

#create Premium Storage account
New-AzureStorageAccount -StorageAccountName "mypremstorage" -Location "China East" -Type "Premium_LRS"

$storageAccount = "mypremstorage"
$adminName = "hadoop"
$adminPassword = "TestAzure123!"
$vmName ="mypremvm"
$location = "China East"
$imageName = "f1179221e23b4dbb89e39d70e5bc9e72__OpenLogic-CentOS-65-20150325"
$vmSize ="Standard_DS2"
$OSDiskPath = "https://" + $storageAccount + ".blob.core.chinacloudapi.cn/vhds/" + $vmName + "_OS_PIO.vhd"

$vm = New-AzureVMConfig -Name $vmName -ImageName $imageName -InstanceSize $vmSize -MediaLocation $OSDiskPath
Add-AzureProvisioningConfig -Linux -VM $vm -LinuxUser $adminName -Password $adminPassword

Set-AzureSubscription -SubscriptionId XXXXXXXXX -CurrentStorageAccountName mypremstorage

New-AzureVM -ServiceName $vmName -VMs $VM -Location $location


#add data disk to the DS VMs

$vm = Get-AzureVM -ServiceName $vmName -Name $vmName
$LunNo = 1
$path = "http://" + $storageAccount + ".blob.core.chinacloudapi.cn/vhds/" + "myDataDisk_" + $LunNo + "_PIO.vhd"
$label = "Disk " + $LunNo
Add-AzureDataDisk -CreateNew -MediaLocation $path -DiskSizeInGB 128 -DiskLabel $label -LUN $LunNo -HostCaching ReadOnly -VM $vm | Update-AzureVm