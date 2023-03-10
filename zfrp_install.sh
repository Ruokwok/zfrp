#!/bin/bash
format_arch() {
	if [ $1 == aarch ]; then echo arm; return 0; fi
	if [ $1 == aarch64 ]; then echo arm64; return 0; fi
	if [ $1 == x86 ]; then echo 386; return 0; fi
	if [ $1 == x86_64 ]; then echo amd64; return 0; fi
	echo $1
}
clear
echo zfrp - 1.0.1
echo ZFRP一键安装脚本
echo
echo "[1]安装"
echo "[2]卸载"
read -e -p 请输入操作序号: oper
if [ ! ${oper} ]; then echo 请输入正确的序号; exit 1; fi
clear
if [ ${oper} == "1" ]; then
	echo 请选择frpc版本
	echo
	echo [1]v0.39.1
	echo [2]v0.40.0
	echo [3]v0.41.0
	echo [4]v0.42.0
	echo [5]v0.43.0
	echo [6]v0.44.0
	echo [7]v0.45.0
	echo [8]v0.46.0
	echo [9]v0.46.1
	echo [10]v0.47.0
	read -e -p 输入序号: ver
	version=null
	case ${ver} in
		1)version="0.39.1" ;;
		2) version="0.40.0" ;;
		3) version="0.41.0" ;;
		4) version="0.42.0" ;;
		5) version="0.43.0" ;;
		6) version="0.44.0" ;;
		7) version="0.45.0" ;;
		8) version="0.46.0" ;;
		9) version="0.46.1" ;;
		10) version="0.47.0" ;;
	esac
	if [ ${version} == null ]; then
		echo "请输入正确的序号"
		exit 1;
	fi
	clear
	arch=null
	auto=`arch`
	echo 请选择系统架构:
	echo 选择错误的架构将导致frp无法启动
	echo
	echo "[1]自动(${auto})"
	echo [2]x86/i386
	echo [3]x86_64/amd64
	echo [4]arm/aarch
	echo [5]arm64/aarch64
	echo [6]mips
	echo [7]mips64
	echo [8]mips64le
	echo [9]mipsle
	echo [10]riscv64
	read -e -p 输入序号: Arch
	case ${Arch} in
		1) arch=`format_arch ${auto}` ;;
		2) arch=386 ;;
		3) arch=amd64 ;;
		4) arch=arm ;;
		5) arch=arm64 ;;
		6) arch=mips ;;
		7) arch=mips64 ;;
		8) arch=mips64le ;;
		9) arch=mipsle ;;
		10) arch=riscv64 ;;
	esac
	if [ $arch == null ]; then
		echo 请输入正确的序号
		exit 1;
	fi
	clear
	echo 开始下载...
	rm -rf frp.tar.gz
	wget -O frp.tar.gz https://github.com/fatedier/frp/releases/download/v${version}/frp_${version}_linux_${arch}.tar.gz
	tar -xvpf frp.tar.gz frp_${version}_linux_${arch}/frpc
	mkdir /etc/zfrp
	mv frp_${version}_linux_${arch}/frpc /etc/zfrp/zfrp_frpc
	wget -O /etc/zfrp/zfrp.sh https://raw.kgithub.com/Ruokwok/zfrp/main/zfrp.sh
	chmod 755 /etc/zfrp/zfrp.sh
	ln /etc/zfrp/zfrp.sh /usr/bin/zfrp
	echo 安装完毕!
	zfrp -help
	rm -rf frp_${version}_linux_${arch}
elif [ ${oper} == "2" ]; then
	read -e -p "是否保留隧道配置文件?(yes/no):" config
	if [ ! ${config} ]; then echo 输入有误!; fi
	if [ ${config} == "no" ]; then
		echo 关闭全部隧道
		zfrp -stopall
		echo 删除文件
		rm -rf /etc/zfrp
		rm -rf /usr/bin/zfrp
		echo 注销服务
		rm -rf /etc/systemd/system/zfrp.service
		systemctl daemon-reload
		echo zfrp已卸载!
	elif [ ${config} == "yes" ]; then
		echo 关闭全部隧道
		zfrp -stopall
		echo 删除文件
		rm -rf /etc/zfrp/pid
		rm -rf /etc/zfrp/logs
		rm -rf /usr/bin/zfrp
		echo 注销服务
		rm -rf /etc/systemd/system/zfrp.service
		systemctl daemon-reload
		echo zfrp已卸载!
	else
		echo 输入有误!
	fi
else
	echo 请输入正确的序号
fi
