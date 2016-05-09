####################################
# Set these variables
####################################
#region - used for creating Azure service names
$nameToken = "myarmhdp" 
#endregion

#region - cluster user accounts
$httpUserName = "admin"  #HDInsight cluster username
$httpPassword = "!"
#endregion

###########################################
# Service names and varialbes
###########################################
#region - service names
$namePrefix = $nameToken.ToLower() + (Get-Date -Format "MMdd")

$resourceGroupName = $namePrefix + "rg"
$hdinsightClusterName = $namePrefix + "hdi"
$defaultStorageAccountName = $namePrefix + "store"
$defaultBlobContainerName = $hdinsightClusterName

$location = "China East"
$clusterSizeInNodes = 1
#endregion

# Treat all errors as terminating
$ErrorActionPreference = "Stop"

###########################################
# Connect to Azure
###########################################
#region - Connect to Azure subscription
Write-Host "`nConnecting to your Azure subscription ..." -ForegroundColor Green
try{Get-AzureRmContext}
catch{Login-AzureRmAccount -EnvironmentName AzureChinaCloud}
#endregion

###########################################
# Create the resource group
###########################################
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

###########################################
# Preapre default storage account and container
###########################################
New-AzureRmStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $defaultStorageAccountName `
    -Type Standard_GRS `
    -Location $location

$defaultStorageAccountKey = Get-AzureRmStorageAccountKey `
                                -ResourceGroupName $resourceGroupName `
                                -Name $defaultStorageAccountName |  %{ $_.Key1 }
$defaultStorageContext = New-AzureStorageContext `
                                -StorageAccountName $defaultStorageAccountName `
                                -StorageAccountKey $defaultStorageAccountKey
New-AzureStorageContainer `
    -Name $hdinsightClusterName -Context $defaultStorageContext 

###########################################
# Create the cluster
###########################################

$httpPW = ConvertTo-SecureString -String $httpPassword -AsPlainText -Force
$httpCredential = New-Object System.Management.Automation.PSCredential($httpUserName,$httpPW)

New-AzureRmHDInsightCluster `
    -ResourceGroupName $resourceGroupName `
    -ClusterName $hdinsightClusterName `
    -Location $location `
    -ClusterSizeInNodes $clusterSizeInNodes `
    -ClusterType Hadoop `
    -OSType Windows `
    -Version "3.2" `
    -HttpCredential $httpCredential `
    -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.chinacloudapi.cn" `
    -DefaultStorageAccountKey $defaultStorageAccountKey `
    -DefaultStorageContainer $hdinsightClusterName 

	#blob.core.chinacloudapi.cn//blob.core.windows.net
	
####################################
# Verify the cluster
####################################
Get-AzureRmHDInsightCluster -ClusterName $hdinsightClusterName 