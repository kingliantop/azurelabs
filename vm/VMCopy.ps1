<#
.Description:
	This small tool will help you to copy VM from source to the destination automaticaaly, it can be used for:
		*one storage account to another storage account in the same/different subscription
		*one vnet to another vnet in the same/different subscription
		*one cloud service to another in the same/different subscription 
.Dependencies
		* Azure powershell（0.9.8）: https://github.com/Azure/azure-powershell/releases
		* AZcopy：http://aka.ms/downloadazcopy
.Usage examples:
    .\VMCopy.ps1 -SourceSubscriptionId SubID 
				 -DestSubscritpionId DesSubID 
				 -SourceCloudServiceName "mycs" 
				 -SourceVMName "myvm" 
				 -DestCloudServiceName "descs" 
				 -DestStorageAccountName "destorage" 
				 -DestLocationName "China East" 
				 -DestVNetName "myvnet"
				 -DestSubNet "desubnet"
				 -DestSuffix "new"
.Source address:
	https://github.com/kingliantop/azurelabs/blob/master/vm/VMCopy.ps1
.Updates
	*Steven Lian（stlian@microsoft.com), August 2015
		* Using subscription ID instead of Subscription Name
		* Update Storage part to test against Mooncake
		* Add Subnet Support
	*Steven Lian（stlian@microsoft.com), Dec 2015
		* Add migration support between VNets in the same subscription
		* Add Suffix support to creat cloud service and disks
		* Add multiple data disks support in the same subscription
#>

Param 
(
    [string] $SourceSubscriptionId,
    [string] $DestSubscritpionId,
    [string] $SourceCloudServiceName,
    [string] $SourceVMName,
    [string] $DestCloudServiceName,
    [string] $DestStorageAccountName,
	[String] $SourceStorageContainerName,
	[string] $DestStorageContainerName,
    [string] $DestLocationName,
    [string] $DestVNetName,
	[string] $DestSubNet,
	[string] $DestSuffix
)

#Check the Azure PowerShell module version
Write-Host "Checking Azure PowerShell module verion" -ForegroundColor Green
$APSMajor =(Get-Module azure).version.Major
$APSMinor =(Get-Module azure).version.Minor
$APSBuild =(Get-Module azure).version.Build
$APSVersion =("$PSMajor.$PSMinor.$PSBuild")

If ($APSVersion -ge 0.9.1)
{
    Write-Host "Powershell version check success" -ForegroundColor Green
}
Else
{
    Write-Host "[ERROR] - Azure PowerShell module must be version 0.9.1 or higher. Exiting." -ForegroundColor Red
    Exit
}

$IsSameSub = $false

if (($SourceSubscriptionId -eq $DestSubscritpionId) -or ($DestSubscritpionId -eq ""))
{
	Write-Host "VM is copied at the same subscription！" -ForegroundColor Green
	$IsSameSub = $true
	$DestSubscritpionId = $SourceSubscriptionId
}

if ($SourceStorageContainerName -eq "")
{
	Write-Host "Using the default source storage container vhds！" -ForegroundColor Green
	$SourceStorageContainerName = "vhds"
}

if ($DestStorageContainerName -eq "")
{
	Write-Host "Using the default destination storage container vhds！" -ForegroundColor Green
	$DestStorageContainerName = "vhds"
}

if ($DestLocationName -eq "")
{
	$DestLocationName = "China East"
}

if ($DestSubNet -eq "")
{
	$DestSubNet = "Subnet-1"
}


Write-Host "`t================= Migration Setting =======================" -ForegroundColor Green
Write-Host "`t  Source Subscription ID 		 = $SourceSubscriptionId           " -ForegroundColor Green
Write-Host "`t Source Cloud Service Name 	 = $SourceCloudServiceName       " -ForegroundColor Green
Write-Host "`t            Source VM Name 	 = $SourceVMName                 " -ForegroundColor Green
Write-Host "`t      Dest Subscription ID 	 = $DestSubscritpionId         	 " -ForegroundColor Green
Write-Host "`t   Dest Cloud Service Name 	 = $DestCloudServiceName         " -ForegroundColor Green
Write-Host "`t Dest Storage Account Name 	 = $DestStorageAccountName       " -ForegroundColor Green
Write-Host "`t Source Storage Container Name = $SourceStorageContainerName   " -ForegroundColor Green
Write-Host "`t Dest Storage Container Name 	 = $DestStorageContainerName   "   -ForegroundColor Green
Write-Host "`t             Dest Location 	 = $DestLocationName             " -ForegroundColor Green
Write-Host "`t                 Dest VNET = $DestVNetName                 	 " -ForegroundColor Green
Write-Host "`t               Dest Subnet = $DestSubNet                 	 	 " -ForegroundColor Green
Write-Host "`t               Dest Suffix = $DestSuffix                 	 	 " -ForegroundColor Green
Write-Host "`t===============================================================" -ForegroundColor Green

$ErrorActionPreference = "Stop"

try{ stop-transcript|out-null }
catch [System.InvalidOperationException] { }

if (($DestSuffix -eq $null) -or ($DestSuffix -eq ""))
{
	$DestSuffix = "cp"
	Write-Host "Set the default cloud service name Suffix as:"+$DestSuffix -ForegroundColor Green
}

$workingDir = (Get-Location).Path
$log = $workingDir + "\VM-" + $SourceCloudServiceName + "-" + $SourceVMName + ".log"
Start-Transcript -Path $log -Append -Force

Select-AzureSubscription -SubscriptionId $SourceSubscriptionId

#######################################################################
#  Check if the VM is shut down 
#  Stopping the VM is a required step so that the file system is consistent when you do the copy operation. 
#  Azure does not support live migration at this time.. 
#######################################################################
$sourceVM = Get-AzureVM –ServiceName $SourceCloudServiceName –Name $SourceVMName
if ( $sourceVM -eq $null )
{
    Write-Host "[ERROR] - The source VM doesn't exist. Exiting." -ForegroundColor Red
    Exit
}

# check if VM is shut down
if ( $sourceVM.Status -notmatch "Stopped" )
{
    Write-Host "[Warning] - Stopping the VM is a required step so that the file system is consistent when you do the copy operation. Azure does not support live migration at this time. If you’d like to create a VM from a generalized image, sys-prep the Virtual Machine before stopping it." -ForegroundColor Yellow
    $ContinueAnswer = Read-Host "`n`tDo you wish to stop $SourceVMName now? (Y/N)"
    If ($ContinueAnswer -ne "Y") { Write-Host "`n Exiting." -ForegroundColor Red; Exit }
    $sourceVM | Stop-AzureVM  -StayProvisioned

    # wait until the VM is shut down
    $sourceVMStatus = (Get-AzureVM –ServiceName $SourceCloudServiceName –Name $SourceVMName).Status
    while ($sourceVMStatus -notmatch "Stopped") 
    {
        Write-Host "Waiting VM $vmName to shut down, current status is $sourceVMStatus" -ForegroundColor Green
        Sleep -Seconds 5
        $sourceVMStatus = (Get-AzureVM –ServiceName $SourceCloudServiceName –Name $SourceVMName).Status
    } 
}

# exporting the source vm to a configuration file, you can restore the original VM by importing this config file
# see more information for Import-AzureVM
$vmConfigurationPath = $workingDir + "\ExportedVMConfig-" + $SourceCloudServiceName + "-" + $SourceVMName +".xml"
Write-Host "Exporting VM configuration to $vmConfigurationPath" -ForegroundColor Green
$sourceVM | Export-AzureVM -Path $vmConfigurationPath

#######################################################################
#  Copy the vhds of the source vm 
#  You can choose to copy all disks including os and data disks by specifying the
#  parameter -DataDiskOnly to be $false. The default is to copy only data disk vhds
#  and the new VM will boot from the original os disk. 
#######################################################################

$sourceOSDisk = $sourceVM.VM.OSVirtualHardDisk
$sourceDataDisks = $sourceVM.VM.DataVirtualHardDisks

# Get source storage account information, not considering the data disks and os disks are in different accounts
$sourceStorageAccountName = $sourceOSDisk.MediaLink.Host -split "\." | select -First 1
$sourceStorageAccount = Get-AzureStorageAccount –StorageAccountName $sourceStorageAccountName
$sourceStorageKey = (Get-AzureStorageKey -StorageAccountName $sourceStorageAccountName).Primary 

Select-AzureSubscription -SubscriptionId $DestSubscritpionId
# Create destination context
$destStorageAccount = Get-AzureStorageAccount | ? {$_.StorageAccountName -eq $DestStorageAccountName} | select -first 1
if ($destStorageAccount -eq $null)
{
    New-AzureStorageAccount -StorageAccountName $DestStorageAccountName -Location $DestLocationName
    $destStorageAccount = Get-AzureStorageAccount -StorageAccountName $DestStorageAccountName
}
$DestStorageAccountName = $destStorageAccount.StorageAccountName
$destStorageKey = (Get-AzureStorageKey -StorageAccountName $DestStorageAccountName).Primary

$sourceContext = New-AzureStorageContext  –StorageAccountName $sourceStorageAccountName -StorageAccountKey $sourceStorageKey -Environment AzureChinaCloud
$destContext = New-AzureStorageContext  –StorageAccountName $DestStorageAccountName -StorageAccountKey $destStorageKey

# Create a container of vhds if it doesn't exist
Set-AzureSubscription -CurrentStorageAccountName $DestStorageAccountName -SubscriptionId $DestSubscritpionId
#if ((Get-AzureStorageContainer -Context $destContext -Name vhds -ErrorAction SilentlyContinue) -eq $null)
if ((Get-AzureStorageContainer -Name $DestStorageContainerName -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "Creating a container vhds in the destination storage account." -ForegroundColor Green
#    New-AzureStorageContainer -Context $destContext -Name vhds
	New-AzureStorageContainer -Name $DestStorageContainerName	 
}

$allDisks = @($sourceOSDisk) + $sourceDataDisks
$destDataDisks = @()
# Copy all data disk vhds
# Start all async copy requests in parallel.
foreach($disk in $allDisks)
{
    $blobName = $disk.MediaLink.Segments[2]
    # copy all data disks 
    Write-Host "Starting copying data disk $($disk.DiskName) at $(get-date)." -ForegroundColor Green
    $sourceBlob = "https://" + $disk.MediaLink.Host + "/" + $SourceStorageContainerName + "/"
    $targetBlob = $destStorageAccount.Endpoints[0] + $DestStorageContainerName + "/"
    $azcopylog = "azcopy-" + $SourceCloudServiceName + "-" + $SourceVMName +".log"
    Write-Host "Start copy vhd to destination storage account"  -ForegroundColor Green
    Write-Host .\azcopy\AzCopy\AzCopy.exe /Source:$sourceBlob /Dest:$targetBlob /SourceKey:$sourceStorageKey /DestKey:$destStorageKey /Pattern:$blobName /SyncCopy /v:$azcopylog -ForegroundColor Green
    D:\migvm\tools\AzCopy\AzCopy.exe /Source:$sourceBlob /Dest:$targetBlob /SourceKey:$sourceStorageKey /DestKey:$destStorageKey /Pattern:$blobName /SyncCopy /v:$azcopylog 

    if ($disk –eq $sourceOSDisk)
    {
        $destOSDisk = $targetBlob + $blobName
    }
    else
    {
        $destDataDisks += $targetBlob + $blobName
    }
}

# Create OS and data disks 
Write-Host "Add VM OS Disk. OS "+ $sourceOSDisk.OS +"diskName:" + $sourceOSDisk.DiskName + "Medialink:"+ $destOSDisk  -ForegroundColor Green

$disknameOS = $sourceOSDisk.DiskName+$DestSuffix

Add-AzureDisk -OS $sourceOSDisk.OS -DiskName $disknameOS -MediaLocation $destOSDisk
# Attached the copied data disks to the new VM
foreach($currenDataDisk in $destDataDisks)
{
    $diskName = ($sourceDataDisks | ? {$currenDataDisk.EndsWith($_.MediaLink.Segments[2])}).DiskName+$DestSuffix
    Write-Host "Add VM Data Disk $diskName" -ForegroundColor Green
    Add-AzureDisk -DiskName $diskName -MediaLocation $currenDataDisk
}

Write-Host "Import VM from " $vmConfigurationPath -ForegroundColor Green
Set-AzureSubscription -SubscriptionId $DestSubscritpionId -CurrentStorageAccountName $DestStorageAccountName


# Manually change the data diskname in the same subscription coz it can't be same
if($IsSameSub)
{
	$ContinueAnswer = Read-Host "`n`tPlease update the Diskname in the configuration file "+ $vmConfigurationPath +", just add your suffix $DestSuffix to the filename! Then press ENTER to continue.."
}
# Import VM from previous exported configuration plus vnet info
if (( Get-AzureService | Where { $_.ServiceName -eq $DestCloudServiceName } ).Count -eq 0 )
{
    New-AzureService -ServiceName $DestCloudServiceName -Location $DestLocationName
}
	
Import-AzureVM -Path $vmConfigurationPath | Set-AzureSubnet -SubnetNames $DestSubNet | New-AzureVM -ServiceName $DestCloudServiceName -VNetName $DestVNetName -WaitForBoot
