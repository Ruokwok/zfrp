#!/bin/bash

path=/etc/zfrp/
frpc=zfrp_frpc
version=1.0.4

function init() {
	if [ ! -d "${path}logs" ]; then mkdir "${path}logs"; fi
	if [ ! -d "${path}pid" ]; then mkdir "${path}pid"; fi
	if [ ! -d "${path}config" ]; then mkdir "${path}config"; fi
}
function read_ini(){
    fid=$1
    section=$2
    option=$3

    test ! -f $fid && echo "不存在文件$fid" && return 2
    if [ $# -eq 3 ] ; then
        local src=$(cat $fid | awk '/\['$section'\]/{f=1;next} /\[*\]/{f=0} f' |
        grep $option |
        grep '='     |
        cut -d'=' -f2|
        cut -d'#' -f1|
        cut -d';' -f1|
        awk '{gsub(/^\s+|\s+$/, "");print}')
        printf $src
        test ${#src} -eq 0 && return 2 || return 0
    else
        return 2
    fi
}
function run_frpc(){
	nohup ${path}${frpc} -c ${path}config/$1.ini > "${path}logs/$1.log" 2>&1& echo $! > "${path}pid/$1.pid"
}
function status() {
	pids=$(pgrep ${frpc});
	[[ ${pids[@]/$1/} != ${pids[@]} ]] && echo $1 || echo "null"
}
init
if [ $# -eq 0 ]; then
	echo "zfrp -help 获取帮助"
	exit 0
fi
if [ $# -gt 0 ] && [ $1 == "-help" ]; then
	echo zfrp 用法:
	echo -e "\t-help\t\t获取帮助"
	echo -e "\t-v\t\t查看版本"
	echo -e "\t-s\t\t快速创建隧道(引导)"
	echo -e "\t-S\t\t创建隧道"
	echo -e "\t-run [name]\t启动隧道"
	echo -e "\t-stop [name]\t停止隧道"
	echo -e "\t-edit [name]\t编辑隧道配置"
	echo -e "\t-remove [name]\t删除隧道"
	echo -e "\t-log [name]\t查看隧道日志"
	echo -e "\t-ls\t\t查看隧道列表"
	echo -e "\t-runall\t\t启动所有隧道"
	echo -e "\t-stopall\t停止所有隧道"
	echo -e "\t-enable\t\t设置开机自启"
	echo -e "\t-pid\t\t查看frpc进程的PID"
	exit 0
fi
if [ $# -gt 0 ] && [ $1 == "-s" ]; then
	echo 开始创建新隧道
	read -e -p 请输入隧道名称: frp_name
	if [ ! ${frp_name} ]; then
		echo 不能为空！
		exit 1;
	fi
	if [ -f ${path}config/${frp_name}.ini ]; then
		echo 该隧道已经存在!
		exit 1
	fi
	read -e -p 服务端地址: frp_server_ip
	if [ ! ${frp_server_ip} ]; then
                echo 不能为空！
                exit 1;
        fi
	read -e -p "服务端端口(7000):" frp_server_port
	if [ ! ${frp_server_port} ]; then
		frp_server_port=7000
	fi
	read -e -p "客户端地址(127.0.0.1):" frp_client_ip
        if [ ! ${frp_client_ip} ]; then
                frp_client_ip="127.0.0.1"
        fi
	read -e -p "客户端端口(22):" frp_client_port
        if [ ! ${frp_client_port} ]; then
                frp_client_port=22
        fi
	read -e -p 远程端口: frp_remote
	if [ ! ${frp_remote} ]; then
		echo 不能为空！
		exit 1;
	fi
	read -e -p "网络协议(tcp/udp):" frp_p
        if [ ! ${frp_p} ]; then
                echo 不能为空!
                exit 1;
        fi
        if [ ${frp_p} != "tcp" ] && [ ${frp_p} != "udp" ]; then
                echo "请输入正确的协议!(tcp/udp)"
                exit 1;
        fi
        
        echo -e "[common]
server_addr = ${frp_server_ip}
server_port = ${frp_server_port}

[${frp_name}]
type = ${frp_p}
local_ip = ${frp_client_ip}
local_port = ${frp_client_port}
remote_port = ${frp_remote}" > "${path}config/${frp_name}.ini"
	echo 创建成功!
	exit 0
fi

if [ $# -gt 0 ] && [ $1 == "-run" ]; then
	if [ $2 ] && [ -f "${path}config/$2.ini" ]; then
		if [ -f "${path}pid/$2.pid" ]; then
			pid=`cat ${path}pid/$2.pid`
			stat=`status ${pid}`
			if [ ${stat} != "null" ]; then
				echo 该隧道正在运行
				exit 1
			else
				run_frpc $2
				exit 0
			fi
		else
			run_frpc $2
			exit 0
		fi
	else
		echo 请输入正确的隧道名称
		exit 1
	fi
fi

if [ $# -gt 0 ] && [ $1 == "-stop" ]; then
	if [ $2 ] && [ -f "${path}config/$2.ini" ]; then
                if [ -f "${path}pid/$2.pid" ]; then
                        pid=`cat ${path}pid/$2.pid`
			kill -9 ${pid}
			rm -rf ${path}pid/$2.pid
			exit 0;
		else
                        echo "该隧道已经停止"
                        exit 1
                fi
        else
                echo 请输入正确的隧道名称
                exit 1
        fi
fi

if [ $# -gt 0 ] && [ $1 == "-ls" ]; then
	echo -e "名称\t\t服务器\t\t\t本地主机\t\t远程端口\t协议\tPID"
	list=$(ls ${path}config)
	pids=$(pgrep ${frpc})
 	for file in ${list}
	do
		ini_file=${path}config/${file}
		ini_node=${file/.ini/}
		printf "${ini_node}\t"
		if [ ${#ini_node} -lt 9 ]; then
			printf "\t"
		fi
		server=`read_ini ${ini_file} common server_addr`:`read_ini ${ini_file} common server_port`
		printf "${server}\t"
		if [ ${#server} -lt 16 ]; then
			printf "\t"
		fi
		local=`read_ini ${ini_file} ${ini_node} local_ip`:`read_ini ${ini_file} ${ini_node} local_port`
		printf ${local}
		if [ ${#local} -lt 16 ]; then
			printf "\t"
		fi
		printf "\t"
		read_ini ${ini_file} ${ini_node} remote_port
		printf "\t\t"
		read_ini ${ini_file} ${ini_node} type
		printf "\t"
		if [ -f "${path}pid/${ini_node}.pid" ]; then
			pid=`cat ${path}pid/${ini_node}.pid`
			stat=`status ${pid}`
			if [ ${stat} == "null" ]; then echo 已停止; else echo ${stat}; fi
		else
			echo 已停止
		fi
	done
	exit 0
fi
if [ $# -gt 0 ] && [ $1 == "-remove" ]; then
	if [ ! $2 ]; then
		echo "用法:"
		echo "zfrp -remove [隧道名称]"
		exit 1
	elif [ ! -d ${path}config/$2.ini ]; then
		rm -rf ${path}config/$2.ini
		rm -rf ${path}logs/$2.log
		rm -rf ${path}pid/$2.pid
		exit 0
	fi
fi
if [ $# -gt 0 ] && [ $1 == "-v" ]; then
	echo zfrp - ${version}
	printf "frpc - " 
	${path}${frpc} -v
	printf "arch - "
	arch
	echo https://github.com/Ruokwok/zfrp
	exit 0
fi
if [ $# -gt 0 ] && [ $1 == "-log" ]; then
	if [ -f ${path}logs/$2.log ]; then
		cat ${path}logs/$2.log
		exit 0
	else
		echo 该隧道不存在!
		exit 1
	fi
fi
if [ $# -gt 0 ] && [ $1 == "-runall" ]; then
	sum=0;
	list=$(ls ${path}config)
	for file in ${list}
	do
		ini_file=${path}config/${file}
		ini_node=${file/.ini/}
		if [ ! -f ${path}pid/${ini_node}.pid  ]; then
			run_frpc ${ini_node}
			let sum+=1;
		fi
	done
	echo "已启动 ${sum} 个隧道"
	exit 0
fi
if [ $# -gt 0 ] && [ $1 == "-stopall" ]; then
	list=$(pgrep ${frpc})
	sum=0
	for pid in ${list}
	do
		kill -9 ${pid}
		let sum+=1;
	done
	rm -rf ${path}pid
	echo "已停止 ${sum} 个隧道"
	exit 0
fi
if [ $# -gt 0 ] && [ $1 == "-enable" ]; then
	if [ $2 ]; then
		if [ $2 == "on" ]; then
			echo "[Unit]
Description=ZFRP Service
After=network.target
[Service]
Type=simple
User=root
KillMode=none
Restart=no
ExecStartPre=${path}zfrp.sh -stopall
ExecStart=${path}zfrp.sh -start
ExecStop=echo stop
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/zfrp.service
			systemctl daemon-reload
			systemctl enable zfrp.service
			echo zfrp自启动已开启
			exit 0
		elif [ $2 == "off" ]; then
			systemctl disable zfrp.service
			echo zfrp自启动已关闭
			exit 0
		fi
	else
		echo 用法:
		echo -e "zfrp -enable on\t\t开启开机自启动"
		echo -e "zfrp -enable off\t关闭开机自启动"
		exit 0
	fi
fi
if [ $# -gt 0 ] && [ $1 == "-pid" ]; then
	pgrep ${frpc}
	exit 0
fi
if [ $# -gt 0 ] && [ $1 == "-start" ]; then
	net=6;
	while [ true ];
	do
		curl www.baidu.com > /dev/null
		if [ $? == 0 ]; then break; fi
		sleep 3s
	done
	sum=0;
	list=$(ls ${path}config)
	for file in ${list}
	do
		ini_file=${path}config/${file}
		ini_node=${file/.ini/}
		if [ ! -f ${path}pid/${ini_node}.pid  ]; then
			run_frpc ${ini_node}
			let sum+=1;
		fi
	done
	echo "已启动 ${sum} 个隧道"
	exit 0
fi
if [ $# -gt 0 ] && [ $1 == "-edit" ]; then
	if [ ! $2 ]; then
		echo  用法: zfrp -edit [name]
		exit 0
	elif [ -f ${path}config/$2.ini ]; then
		vi ${path}config/$2.ini
		exit 0
	else
		echo 该隧道不存在!
		exit 1
	fi
fi
if [ $# -gt 0 ] && [ $1 == "-S" ]; then
	if [ ! $2 ]; then
		echo 用法: zfrp -S [name]
		exit 0
	else
		echo -e "[common]
server_addr = exmple.com
server_port = 7000

[$2]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 2233" > ${path}config/$2.ini
	vi ${path}config/$2.ini
	exit 0
	fi
fi
${path}zfrp.sh -help
