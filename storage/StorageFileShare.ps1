<#
.SYNOPSIS
       Create Azure storage File Share and test file load

       
.DESCRIPTION
       Create Azure storage File Share and test file load
	   Mount file share at CentOS 7.1

	   sudo yum install samba-client samba-common cifs-utils

       sudo mount -t cifs //mystorageacctfile.file.core.chinacloudapi.cn/myfileshare /mnt/fileshare -o vers=3.0,user=mystorageacctfile,password="497mXWeEKGL7xRLaTcEJ4GKO6zOaPs8uOptyB7j1Qz6bJePu9DkmcR7UdxwwftjLOOqDYSPrdPdvNKlrn8fIkA==",dir_mode=0777,file_mode=0777


.NOTES
       Author: Steven Lian
	   Email:  stlian@microsoft.com
       Date: 2016/05
       Revision: 0.1
#>


$StorageAccountName="mystorageacctfile"
$Location="China East"
$SubscriptionID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$filesharename="myfileshare"


#创建Azure storage存储账号
New-AzureStorageAccount –StorageAccountName $StorageAccountName -Location $Location

#得到存储的key值
$StorageAccountKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName


#设置当前订阅的当前存储账号
Set-AzureSubscription -CurrentStorageAccountName $StorageAccountName -SubscriptionId $SubscriptionID


#Get storage context for further use
$ctx=New-AzureStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey.Primary


#create an file share
$share = New-AzureStorageShare $filesharename -Context $ctx

Get-AzureStorageShare -Context $ctx -Name $filesharename

#创建文件共享目录
New-AzureStorageDirectory -Share $share -Path logs


#上传一个文件到文件共享目录  
Set-AzureStorageFileContent -Share $share -Source d:\hdinsight.publishsettings -Path logs

# 列出目录下的所有文件
Get-AzureStorageFile -Share $share -Path logs | Get-AzureStorageFile






