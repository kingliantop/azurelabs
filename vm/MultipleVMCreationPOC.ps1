
$imageList = Get-AzureVMImage|where {$_.ImageName -eq "55bc2b193643443bb879a78bda516fc8__Win2K8R2SP1-Datacenter-201503.01-zh.cn-127GB.vhd"}

$image=$imageList[0]

$CAFMKTWEB3PublicIP = New-AzureReservedIP 
-ReservedIPName 'CAFMKTWEB3PublicIP' -Label 'CAFMKTWEB3PublicIP' -Location 'China East'

Get-AzureReservedIP -ReservedIPName 'CAFMKTWEB3PublicIP'

$CAFMKTDB2PublicIP = New-AzureReservedIP 
-ReservedIPName 'CAFMKTDB2PublicIP' -Label 'CAFMKTDB2PublicIP' -Location 'China East'


New-AzureVMConfig -Name 'mktWebserver3' -InstanceSize A7 -ImageName $image.ImageName 
| Add-AzureProvisioningConfig -Windows -AdminUsername 'webadmin' -Password 'Webserver3!'
| Set-AzureSubnet -SubnetNames 'Subnet-2' | Set-AzureStaticVNetIP -IPAddress '10.32.0.10' 
| New-AzureVM -ServiceName 'WebSRV3Service' -VNetName 'mktvnet' –ReservedIPName 'CAFMKTWEB3PublicIP' -Location 'China East'


$imageList = Get-AzureVMImage|where {$_.ImageName -eq "74bb2f0b8dcc47fbb2914b60ed940c35__SQL-Server-2008R2SP2-GDR-10.50.4021.0-Enterprise-CHS-Win2K8R2-CY14SU02"}
$image=$imageList[0]
$CAFMKTDB2PublicIP = New-AzureReservedIP -ReservedIPName 'CAFMKTDB2PublicIP' -Label 'CAFMKTDB2PublicIP' -Location 'China East'
Get-AzureReservedIP -ReservedIPName 'CAFMKTDB2PublicIP'

New-AzureVMConfig -Name 'mktSQLDB' -InstanceSize A7 -ImageName $image.ImageName 
| Add-AzureProvisioningConfig -Windows -AdminUsername 'dbadmin' -Password 'Mydatabase2!'
| Set-AzureSubnet -SubnetNames 'Subnet-2' | Set-AzureStaticVNetIP -IPAddress '10.32.0.18' 
| New-AzureVM -ServiceName 'DB2Service' -VNetName 'mktvnet' –ReservedIPName 'CAFMKTDB2PublicIP' -Location 'China East'

#update static private IP address for existing VMs

Test-AzureStaticVNetIP –VNetName mktVNet –IPAddress 10.8.0.10
Get-AzureVM -ServiceName mktwebserver -Name mktwebserver1 | Set-AzureStaticVNetIP -IPAddress 10.8.0.10 | Update-AzureVM
Get-AzureVM -ServiceName mktwebserver -Name mktwebserver2 | Set-AzureStaticVNetIP -IPAddress 10.8.0.12 | Update-AzureVM

Get-AzureVM -ServiceName mktDB1 -Name mktDB1 | Set-AzureStaticVNetIP -IPAddress 10.8.0.18 | Update-AzureVM

#must create VM with Powershell if you want to use reservedIP

$imageList = Get-AzureVMImage|where {$_.ImageName -eq "CentOS-5-10-x86-64"}
$image=$imageList[0]

#create web server 1
$CAFWEB1PublicIP = New-AzureReservedIP -ReservedIPName 'CAFWEB1PublicIP' -Label 'CAFWEB1PublicIP' -Location 'China East'
Get-AzureReservedIP -ReservedIPName 'CAFWEB1PublicIP'

New-AzureVMConfig -Name 'mktWEB1' -InstanceSize A7 -ImageName $image.ImageName 
| Add-AzureProvisioningConfig -Linux -LinuxUser 'webuser' -Password 'Web1@caf'
| Set-AzureSubnet -SubnetNames 'Subnet-1' | Set-AzureStaticVNetIP -IPAddress '10.8.0.10' 
| New-AzureVM -ServiceName 'mktWEB' -VNetName 'mktvnet' –ReservedIPName 'CAFWEB1PublicIP' -Location 'China East'

#create web server 2
$CAFWEB2PublicIP = New-AzureReservedIP -ReservedIPName 'CAFWEB2PublicIP' -Label 'CAFWEB2PublicIP' -Location 'China East'
Get-AzureReservedIP -ReservedIPName 'CAFWEB2PublicIP'

New-AzureVMConfig -Name 'mktWEB2' -InstanceSize A7 -ImageName $image.ImageName 
| Add-AzureProvisioningConfig -Linux -LinuxUser 'webuser' -Password 'Web2@caf'
| Set-AzureSubnet -SubnetNames 'Subnet-1' | Set-AzureStaticVNetIP -IPAddress '10.8.0.11' 
| New-AzureVM -ServiceName 'mktWEB' -VNetName 'mktvnet' –ReservedIPName 'CAFWEB2PublicIP' -Location 'China East'

#create DB Server 1: MySQL
$CAFDB1PublicIP = New-AzureReservedIP -ReservedIPName 'CAFDB1PublicIP' -Label 'CAFDB1PublicIP' -Location 'China East'
Get-AzureReservedIP -ReservedIPName 'CAFDB1PublicIP'

New-AzureVMConfig -Name 'mktDB1' -InstanceSize A7 -ImageName $image.ImageName 
| Add-AzureProvisioningConfig -Linux -LinuxUser 'dbuser' -Password 'db1@caf'
| Set-AzureSubnet -SubnetNames 'Subnet-1' | Set-AzureStaticVNetIP -IPAddress '10.8.0.18' 
| New-AzureVM -ServiceName 'mktDB1' -VNetName 'mktvnet' –ReservedIPName 'CAFDB1PublicIP' -Location 'China East'

