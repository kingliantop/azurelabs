<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/kingliantop/azurelabs/master/AzureChinaARMTemplate/VM-multiple-datadisks-SSD/template.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=/https://raw.githubusercontent.com/kingliantop/azurelabs/master/AzureChinaARMTemplate/VM-multiple-datadisks-SSD/template.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

本模板由Steven Lian创建，主要完成在Azure China自动化创建多个Linux(centOS 6.8 by default)虚拟机（D/DS系列），挂载多个SSD硬盘，并自动创建RAID0磁盘，提高IOPS性能。该脚本支持：
1. NSG
2. public IP及DNS
3. 多个data disk
4. avaiability set 
5. 自动化RAID0创建

请注意：本模板和脚本只在CentOS6.8下我做了测试，对于其他版本Linux，请自行测试，有过有问题，请report case，我会做个更新

如何使用：
1.	克隆或者下载当前repo
2.  修改parameter.json中的参数,比如用户名，密码，多少台VM等等
3.	Linux/Mac用户请使用deploy.sh部署（需要安装Azure CLI）
4.	Windows用户需要使用deploy.ps1部署
5.  也可以使用该连接上方直接图形化部署
