Get-AzurePublishSettingsFile -Environment AzureChinaCloud
Import-AzurePublishSettingsFile 'D:\BOSCH-5-26-2015-credentials.publishsettings'

Select-AzureSubscription -SubscriptionId XXXXXXXXXXX

Get-AzureSubscription -Default

Set-AzureSubscription -SubscriptionId 46a7dc46-f074-4d13-a137-298c4fc99b0a -CurrentStorageAccountName bshstorage

#get the CentOS 6.5 image
$imageList = Get-AzureVMImage | where-object { $_.Label -like "OpenLogic 6*" }
$imageName = $imageList[0].ImageName

#Get reserved public IP address for DB
$BOSCHDBPubIP = New-AzureReservedIP -ReservedIPName 'BOSCHDBPubIP' -Label 'BOSCHDBPubIP' -Location 'China East'

New-AzureVMConfig -Name 'bshdev' -InstanceSize A7 -ImageName $imageName 
| Add-AzureProvisioningConfig -Linux -LinuxUser 'mobility' -Password 'Bosch@123!'
| Set-AzureSubnet -SubnetNames 'Subnet-1' | Set-AzureStaticVNetIP -IPAddress '10.0.0.10' 
| New-AzureVM -ServiceName 'bshdevsvc' -VNetName 'bshvnet' -Location 'China East'

New-AzureVMConfig -Name 'bshoracle' -InstanceSize D13 -ImageName $imageName 
| Add-AzureProvisioningConfig -Linux -LinuxUser 'mobility' -Password 'Bosch@123!'
| Set-AzureSubnet -SubnetNames 'Subnet-1' | Set-AzureStaticVNetIP -IPAddress '10.8.0.11' 
| New-AzureVM -ServiceName 'bshorclsvc' -VNetName 'bshvnet' –ReservedIPName 'BOSCHDBPubIP' -Location 'China East'
