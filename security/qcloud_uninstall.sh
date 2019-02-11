#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function set_fonts_colors(){
	default_fontcolor="\033[0m"
	red_fontcolor="\033[31m"
	green_fontcolor="\033[32m"
	info_fontcolor="\033[36m"
	error_font="${red_fontcolor}[Error]${default_fontcolor}"
	ok_font="${green_fontcolor}[OK]${default_fontcolor}"
	info_font="${info_fontcolor}[Info]${default_fontcolor}"
	check_os
}

function check_os(){
	[ "$EUID" -ne "0" ] && echo -e "${error_font}Please run as root, and retry." && exit 1
	if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" ] || [ -e "/etc/redhat-release" ]; then
		System_OS="CentOS"
		[ -n "$(grep ' 7\.' /etc/redhat-release)" ] && OS_Version="7"
		[ -n "$(grep ' 6\.' /etc/redhat-release)" ] || [ -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && OS_Version="6"
		[ -n "$(grep ' 5\.' /etc/redhat-release)" ] || [ -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && OS_Version="5"
		[ -z "${OS_Version}" ] && [ ! -e "$(command -v lsb_release)" ] && { yum -y update; yum -y install redhat-lsb-core; } >/dev/null 2>&1 && OS_Version="$(lsb_release -sr 2>/dev/null | awk -F. '{print $1}')"
	elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" ]|| [ -e /etc/system-release ]; then
		System_OS="CentOS"
		OS_Version="6"
	elif [ -n "$(grep Debian /etc/issue)" ] || [ "$(lsb_release -is 2>/dev/null)" == 'Debian' ]; then
		System_OS="Debian"
		[ ! -e "$(command -v lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; } >/dev/null 2>&1
		OS_Version="$(lsb_release -sr 2>/dev/null | awk -F. '{print $1}')"
		[ -n "$(grep 'buster' /etc/issue)" ] && OS_Version="10"
	elif [ -n "$(grep Deepin /etc/issue)" ] || [ "$(lsb_release -is 2>/dev/null)" == 'Deepin' ]; then
		System_OS="Debian"
		[ ! -e "$(command -v lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; } >/dev/null 2>&1
		OS_Version="$(lsb_release -sr 2>/dev/null | awk -F. '{print $1}')"
	elif [ -n "$(grep Ubuntu /etc/issue)" ] || [ "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' ]; then
		System_OS="Ubuntu"
		[ ! -e "$(command -v lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; } >/dev/null 2>&1
		OS_Version="$(lsb_release -sr 2>/dev/null | awk -F. '{print $1}')"
	else
		clear
		echo -e "${error_font}The OS isn't supported, please use CentOS/Debian/Ubuntu, and retry."
		exit 1
	fi
	update_os
}

function update_os(){
	echo -e "${info_font}Updating system, it may take some times..."
	[ "${System_OS}" == "CentOS" ] && yum update -y >/dev/null 2>&1
	[ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" -le "6" ] && yum install -y curl iptables >/dev/null 2>&1
	[ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" -ge "7" ] && yum install -y curl firewalld >/dev/null 2>&1
	[ "${System_OS}" == "Debian" ] || [ "${System_OS}" == "Ubuntu" ] && { apt-get update -y; apt-get install -y curl iptables; } >/dev/null 2>&1
	echo -e "${ok_font}Done."
	uninstall_service
}

function uninstall_service(){
	echo -e "${info_font}Uninstalling Tencent-Yunjing..."
	/usr/local/qcloud/stargate/admin/uninstall.sh >/dev/null 2>&1
	/usr/local/qcloud/YunJing/uninst.sh >/dev/null 2>&1
	/usr/local/qcloud/monitor/barad/admin/uninstall.sh >/dev/null 2>&1
	rm -rf /usr/local/qcloud >/dev/null 2>&1
	echo -e "${ok_font}Done."
	echo -e "${info_font}Reseting crontab..."
	crontab -r >/dev/null 2>&1
	echo -e "*/20 * * * * /usr/sbin/ntpdate ntpupdate.tencentyun.com >/dev/null &" >/tmp/ntpupdate_crontab
	crontab /tmp/ntpupdate_crontab >/dev/null 2>&1
	rm -rf /tmp/ntpupdate_crontab >/dev/null 2>&1
	echo -e "${ok_font}Done."
	echo -e "\n${ok_font}Succeeded in uninstalling Tencent-Yunjing, thank you for your using."
}

	set_fonts_colors