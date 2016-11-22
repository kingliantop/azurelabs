<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fahpeng%2FMesosMarathon%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=/https%3A%2F%2Fraw.githubusercontent.com%2Fahpeng%2FMesosMarathon%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

本模板使用ACS-Engine(https://github.com/Azure/acs-engine)生成,适合于在中国部署，在使用之前：
1.	克隆或者下载当前所有文件
2.	修改azuredeploy.json中的http://YOURCHINASERVER为你自己的服务器，
3.	修改azuredeploy.parameters.json中的所有标为CHANGIT的地方
4.	修改deploy.ps1文件中deployName作为你的资源组名称
5.	登陆你的Azure账户，使用ARM模式，执行deploy.ps1部署
6.	Linux和Mac用户可以只用Azure CLI部署

感谢Mark Peng同学的支持鼓励：）