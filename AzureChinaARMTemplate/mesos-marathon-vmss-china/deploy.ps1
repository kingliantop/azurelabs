$VerbosePreference="Continue"
$deployName="YOURRESOURCEGROUPNAME"
$RGName=$deployName
$locName="China North"

$templateFile= "azuredeploy.json"
$templateParameterFile= "azuredeploy.parameters.json"
New-AzureRmResourceGroup -Name $RGName -Location $locName -Force

echo New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateFile $templateFile
New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile
