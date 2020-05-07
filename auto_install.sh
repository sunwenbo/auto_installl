#!/bin/bash
#This script is used auto install deployments and check Rely on the service
#2020-0506 sunwenbo
set -e
DASESHELL=$(cd `dirname $0`; pwd)
export TIME=`date`
export MYSQLIP=`/usr/bin/kubectl get service -o wide  | grep mysql  |awk '{print $3}'`
export MYSQLPORT=`/usr/bin/kubectl get service -o wide  | grep mysql  |awk '{print $5}' | awk -F':' '{print $1}'`
export MYSQLPASSWORD='sunwenbo'
export REDISIP=`/usr/bin/kubectl get service -o wide  | grep redis  |awk '{print $3}'`
export REDISPORT=`/usr/bin/kubectl get service -o wide  | grep redis  |awk '{print $5}'`
export APP_HOME=/root/job/deploy

###########################################################################################################################
function printMenu() {
	echo -e "\033[32m                                                                     \033[0m"
	echo -e "\033[33m 当前系统时间为:$TIME \033[0m"
	echo -e "\033[32m                                                                     \033[0m"
	echo -e "\033[32m ##########################自动部署启动脚本##########################\033[0m"
	echo -e "\033[32m ##                                                                ##\033[0m"
	echo -e "\033[32m ##                         环境检测                               ##\033[0m"
	echo -e "\033[32m ##                                                                ##\033[0m"
	echo -e "\033[32m ##             1.mysql检测         2.redis检测                    ##\033[0m"
	echo -e "\033[32m ##                                                                ##\033[0m"
	echo -e "\033[32m ##                         应用部署                               ##\033[0m"
	echo -e "\033[32m ##                                                                ##\033[0m"
	echo -e "\033[32m ##          3.service服务部署         4.priv服务部署              ##\033[0m"
	echo -e "\033[32m ##          5.console服务部署         6.mysql安装                 ##\033[0m"
	echo -e "\033[32m ##          7.redis安装               8.退出                      ##\033[0m"
	echo -e "\033[32m ##                                                                ##\033[0m"
	echo -e "\033[32m ##                                                                ##\033[0m"
	echo -e "\033[32m ##########################自动部署启动脚本##########################\033[0m"
}

###########################################################################################################################
function checkMysql() {
	which "mysql" > /dev/null
	if [ $? -ne 0 ];then
	echo command not exist
	fi
	echo -e "\033[32m                                                                 \033[0m"
	echo -e "\033[32m 开始检查是否有mysql环境 \033[0m"
	read -p "请输入mysql的IP:" MYSQLIP
	read -p "请输入mysql的USER:" MYSQLUSER
	read -p "请输入mysql的PASSWORD:" MYSQLPASSWORD
	read -p "请输入mysql的端口号:" MYSQLPORT
	/usr/bin/mysql -h"$MYSQLIP" -u"$MYSQLUSER" -p"$MYSQLPASSWORD" -P"$MYSQLPORT" -e "flush privileges"   #> /dev/null 
	if [ $? -eq 0 ];then
		echo -e "\033[32m 测试连接MYSQL数据库成功 \033[0m"
		echo -e "\033[32m Mysql服务正常 \033[0m"
		echo -e "\033[32m MysqlIp: $MYSQLIP  MysqlPort: $MYSQLPORT \033[0m"; sleep 3;
	else
		num=`netstat -ntlp |grep $MYSQLPORT |wc -l`
		if [ $num -ne 1 ];then
			echo -e "\033[31m 未检测到有mysql相对应的进程!请检测mysql是否正常启动,如果没有安装mysql,请根据菜单提示安装mysql! \033[0m"
			sleep 3 ; 
		fi
	fi
}

###########################################################################################################################
function checkRedis() {
	which "redis-cli" > /dev/null
	if [ $? -ne 0 ];then
	echo command not exist
	fi
        echo -e "\033[32m                                                                 \033[0m"
	echo -e "\033[32m 开始检查本地是否有redis环境......  \033[0m";sleep 3;
        #read -p "请输入redis的IP:" REDISIP
        #read -p "请输入redis的USER:" REDISUSER
        #read -p "请输入redis的PASSWORD:" REDISPASSWORD
        #read -p "请输入redis的端口号:" REDISPORT
	num=`ps -elf |grep -i redis |grep -v grep | wc -l`
        if [ $num -ne 1 ];then
             echo -e "\033[31m 未检测到有redis相对应的进程!请检测redis是否正常启动,如果没有安装redis,请根据菜单提示安装redis \033[0m"
             sleep 3 ;
	else
	     echo -e "\033[32m redis服务正常.... \033[0m"
	     echo -e "\033[32m RedisIp:$REDISIP RedisPort:$REDISPORT \033[0m"
        fi

}

###########################################################################################################################
function installmysql() {
	
	num1=`netstat -ntlp |grep 3306 |wc -l`
	num2=`kubectl get service  |grep 3306 |wc -l`
        if [[ $num1 -eq 1 ]] || [[ $num2 -eq 1 ]];then
             echo -e "\033[32m Mysql服务已安装并且已启动,请连接使用..... \033[0m"
	     echo -e "\033[32m MysqlIp: $MYSQLIP  MysqlPort: $MYSQLPORT \033[0m"; sleep 3;
             sleep 3 ;
        else
	        echo -e "\033[32m 开始使用yaml安装mysql...... \033[0m"
       		/usr/bin/kubectl apply -f /root/job/mysql/
        	if [ $? -eq 0 ];then
                	echo -e "\033[32m Mysql安装已完成...... \033[0m"
                	/usr/bin/kubectl get service -o wide  | grep mysql  |awk '{print $1,$2,$3,$5}'
                	MYSQLIP=`/usr/bin/kubectl get service -o wide  | grep mysql  |awk '{print $3}'`
                	MYSQLPORT=`/usr/bin/kubectl get service -o wide  | grep mysql  |awk '{print $5}'`
                	echo -e "\033[32m MysqlIp: $MYSQLIP  MysqlPort: $MYSQLPORT \033[0m"; sleep 3;
		else
			echo -e "\e[1;33;41m Mysql服务启动异常,请检查...... \e[0m"
        	fi
        fi

}
#installmysql

###########################################################################################################################
function installredis() {
	num1=`ps -elf |grep -i redis |grep -v grep | wc -l`
        num2=`kubectl get service  |grep 6379 |wc -l`
        if [[ $num1 -eq 1 ]] || [[ $num2 -eq 1 ]];then
             echo -e "\033[32m Redis服务已安装并且已启动,请连接使用..... \033[0m"
             echo -e "\033[32m RedisIp: $REDISIP  RedisPort: $REDISPORT \033[0m"; sleep 3;
             sleep 3 ;
	else
        	echo -e "\033[32m 开始使用yaml文件安装redis......  \033[0m"
        	/usr/bin/kubectl apply -f /root/job/redis/
        	if [ $? -eq 0 ];then
                	echo -e "\033[32m Redis安装已完成...... \033[0m"
                	/usr/bin/kubectl get service -o wide  | grep redis  |awk '{print $1,$2,$3,$5}'
                	echo -e "\033[32m RedisIp: $REDISIP  Port: $REDISPORT \033[0m"; sleep 3;
		else
			echo -e "\e[1;33;41m redis服务启动异常,请检查...... \e[0m"
        	fi
	fi
}

###########################################################################################################################
function installservice() {
echo -e "\033[32m service正在安装,请稍等...... \033[0m";sleep 3;
cat > $APP_HOME/public/csservice-configmap.yaml <<EOF
apiVersion: v1
data:
  druid.properties: "#\\u516c\\u53f8\\u5f00\\u53d1\r\njdbc.serverIP=$MYSQLIP\r\njdbc.serverPort=$MYSQLPORT\r\njdbc.dbName=uat_citycloud\r\njdbc.user=uat_citycloud\r\njdbc.password=$MYSQLPASSWORD\r\n\r\njdbc.initialSize=1\r\njdbc.minIdle=1\r\njdbc.maxActive=5\r\njdbc.maxWait=60000\r\njdbc.timeBetweenEvictionRunsMillis=60000\r\njdbc.minEvictableIdleTimeMillis=300000\r\njdbc.maxPSCache=20\r\n"
  dubbo.properties: "dubbo.registry=N/A\r\n#dubbo.registry=multicast://224.5.6.7:1234\r\n#dubbo.registry=zookeeper://192.168.1.220:2181\r\ndubbo.protocol.port=30164"
  file.properties: "order.downfile.path=/app/deploy/downloadPagePath\r\norder.rcfile.path=/app/deploy/downloadPagePath\r\n"
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: citycsservice-configmap
EOF

cat > $APP_HOME/public/service-configmap.yaml <<EOF
apiVersion: v1
data:
  druid.properties: "#\\u516c\\u53f8\\u5f00\\u53d1\r\njdbc.serverIP=$MYSQLIP\r\njdbc.serverPort=$MYSQLPORT\r\njdbc.dbName=uat_citycloud\r\njdbc.user=uat_citycloud\r\njdbc.password=$MYSQLPASSWORD\r\n\r\n\r\njdbc.initialSize=1\r\njdbc.minIdle=1\r\njdbc.maxActive=5\r\njdbc.maxWait=60000\r\njdbc.timeBetweenEvictionRunsMillis=60000\r\njdbc.minEvictableIdleTimeMillis=300000\r\njdbc.maxPSCache=20\r\n"
  dubbo.properties: "dubbo.registry=N/A\r\n#dubbo.registry=multicast://224.5.6.7:1234\r\n#dubbo.registry=zookeeper://192.168.1.220:2181\r\ndubbo.protocol.port=30166"
  file.properties: "order.downfile.path=/app/deploy/downloadPagePath\r\norder.rcfile.path=/app/deploy/downloadPagePath\r\n"
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: cityservice-configmap
EOF

	/usr/bin/kubectl apply -f $APP_HOME/public/
	num1=`kubectl get pod  |grep public |awk -F'/' '{print $NR}' |awk '{print $2}'`
	num2=`kubectl get service  | grep public |wc -l`
	if [[ $num1 -eq 1 ]] && [[ $num2 -eq 1 ]] ;then
        	echo -e "\033[32m service服务启动成功......  \033[0m"
	else
		
		echo -e "\e[1;33;41m service服务启动异常,请检查...... \e[0m"
		
	fi
		 
}

###########################################################################################################################
function installpriv() {
cat > $APP_HOME/priv/priv-configmap.yaml <<EOF
apiVersion: v1
data:
  druid.properties: "#\\u5f00\\u53d1\r\n#\\u516c\\u53f8\\u5f00\\u53d1\r\njdbc.serverIP=$MYSQLIP\r\njdbc.serverPort=$MYSQLPORT\r\njdbc.dbName=uat_citycloud\r\njdbc.user=uat_citycloud\r\njdbc.password=$MYSQLPASSWORD\r\n\r\njdbc.initialSize=1\r\njdbc.minIdle=1\r\njdbc.maxActive=5\r\njdbc.maxWait=60000\r\njdbc.timeBetweenEvictionRunsMillis=60000\r\njdbc.minEvictableIdleTimeMillis=300000\r\njdbc.maxPSCache=20\r\n"
  dubbo.properties: "dubbo.registry=N/A\r\ndubbo.protocol.port=30165"
  file.properties: "#cityconsole   tomcate的IP以及端口\r\ntomc_cityconsole_ip=127.0.0.1\r\ntomc_cityconsole_port=8080\r\n#citycustomservice
    \  tomcate的IP以及端口\r\ntomc_citycustomservice_ip=127.0.0.1\r\ntomc_citycustomservice_port=8081\r\n#citypriv
    \  tomcate的IP以及端口\r\ntomc_citypriv_ip=127.0.0.1\r\ntomc_citypriv_port=8082\r\n"
  redis.properties: "#\\u6d4b\\u8bd5\\u5185\r\nredis.hostName=$REDISIP\r\nredis.port=$REDISPORT\r\n\r\nredis.password=\r\nredis.timeout=10000\r\n"
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: citypriv-configmap

EOF
	/usr/bin/kubectl apply -f $APP_HOME/priv/
	num1=`kubectl get pod  |grep priv |awk -F'/' '{print $NR}' |awk '{print $2}'`
	num2=`kubectl get service  | grep priv |wc -l`
	if [[ $num1 -eq 1 ]] && [[ $num2 -eq 1 ]] ;then
        	echo -e "\033[32m priv服务启动成功......  \033[0m"
	else
		
		echo -e "\e[1;33;41m priv服务启动异常,请检查...... \e[0m"
		
	fi
}
function installconsole() {
cat > $APP_HOME/console/console-configmap.yaml <<EOF
apiVersion: v1
data:
  dubbo.properties: "dubbo.registry=N/A\r\n#dubbo.registry=zookeeper://192.168.1.220:2181\r\ndubbo.timeout=60000\r\ndubbo.reference.privilige=dubbo://priv-service:30165/jieyi.app.dubbo.PriviligeService\r\ndubbo.reference.center=dubbo://public-service:30166/jieyi.app.dubbo.ConsoleService\r\ndubbo.reference.centerfiletrans=dubbo://public-service:30166/jieyi.app.dubbo.FileTransService\r\ndubbo.reference.jdbc=dubbo://public-service:30166/jieyi.app.dubbo.JDBCDaoService\r\ndubbo.reference.logonservice=dubbo://priv-service:30165/jieyi.app.dubbo.LogonService\r\n#dubbo.reference.filedownload=dubbo://127.0.0.1:30258/jieyi.dbconsole.dubbo.BizProccessService\r\n"
  file.properties: "order.downfile.path=/app/deploy/filetmp\r\norder.rcfile.path=/app/deploy/filetmp\r\nbcandyzcard.file.path=/app/deploy/filetmp\r\n\r\n#cityconsole
    \  tomcate的IP以及端口\r\ntomc_cityconsole_ip=127.0.0.1\r\ntomc_cityconsole_port=8080\r\n#citycustomservice
    \  tomcate的IP以及端口\r\ntomc_citycustomservice_ip=127.0.0.1\r\ntomc_citycustomservice_port=8081\r\n#citypriv
    \  tomcate的IP以及端口\r\ntomc_citypriv_ip=127.0.0.1\r\ntomc_citypriv_port=8082\r\nlayout.upfile.path=/app/deploy/rec\r\n#短信发送配置文件\r\nsms.url=http://113.108.68.228:8001/sendSMS.action\r\nsms.userid=admin\r\nsms.companyid=17451\r\nsms.password=81235chdt\r\nsms.validtime=5\r\n#############################################################\r\n#############################################################\r\n#############################################################\r\n#############################################################\r\n#############################################################\r\n"
  otherconfig.properties: "#\\u516c\\u53f8\\u6d4b\\u8bd5\r\ncommunicate.corectlip=127.0.0.1\r\ncommunicate.corectlport=9600\r\nIINS=31048211\r\niss_inst_no=01355850\r\nacqinst=11355850\r\ncardbin=31048701\r\n"
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: cityconsole-configmap
EOF

	/usr/bin/kubectl apply -f $APP_HOME/console/
	num1=`kubectl get pod  |grep console |awk -F'/' '{print $NR}' |awk '{print $2}'`
	num2=`kubectl get service  | grep console |wc -l`
	if [[ $num1 -eq 1 ]] && [[ $num2 -eq 1 ]] ;then
        	echo -e "\033[32m console服务启动成功......  \033[0m"
	else
		
		echo -e "\e[1;33;41m console服务启动异常,请检查...... \e[0m"
		
	fi
}

###########################################################################################################################
while :
   do  
	printMenu
	read -p "请输入你的选择 {1|2|3|4|5|6|7|8:} " input
	echo -e "你的选择是 ${input}\n"

	case $input in
		1)
			checkMysql
		;;
		2)
			checkRedis
		;;
		3)
			installservice
		;;
		4)
			installpriv
		;;
		5)
			installconsole
		;;
		6)
			installmysql
		;;
		7)
			installredis
		;;
		8)
			echo -e "\033[32m正在退出请稍后....  \033[0m"; sleep 3;
			exit 0
		;;
		*)
			echo "输入错误！"
	esac
done
