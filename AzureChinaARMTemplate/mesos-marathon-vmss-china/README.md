<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fahpeng%2FMesosMarathon%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=/https://raw.githubusercontent.com/kingliantop/azurelabs/master/AzureChinaARMTemplate/mesos-marathon-vmss-china/azuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

本模板使用ACS-Engine (https://github.com/Azure/acs-engine) 生成,适合于在中国部署，在使用之前：

1.	克隆或者下载当前repo
2.	修改azuredeploy.json中的http://YOURCHINASERVER为你自己的服务器，
3.	修改azuredeploy.parameters.json中的所有标为CHANGIT的地方
4.	修改deploy.ps1文件中deployName作为你的资源组名称
5.	登陆你的Azure账户，使用ARM模式，执行deploy.ps1部署
6.	Linux和Mac用户也可以用Azure CLI部署
