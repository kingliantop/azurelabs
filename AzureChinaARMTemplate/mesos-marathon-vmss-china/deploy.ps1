$VerbosePreference="Continue"
$deployName="stevenmesosnorthgp"
$RGName=$deployName
$locName="China North"

$templateFile= "mesos-cluster-vmss.json"
$templateParameterFile= "cluster.parameters.json"
New-AzureRmResourceGroup -Name $RGName -Location $locName -Force

echo New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateFile $templateFile
New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile
