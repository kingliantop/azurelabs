<#
.SYNOPSIS
       Deploy Azure ARM templates
       
.DESCRIPTION
       Deploy Azure ARM templates

.NOTES
       Author: Steven Lian
	   Email:  stlian@microsoft.com
       Date: 2016/07
       Revision: 0.1
#>

$VerbosePreference="Continue"
$deployName="stevenwebscale"
$RGName=$deployName
$locName="China North"

$templateFile= "azuredeploy.json"
$templateParameterFile= "azuredeploy.parameters.json"
New-AzureRmResourceGroup -Name $RGName -Location $locName -Force

echo New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateFile $templateFile
New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile
