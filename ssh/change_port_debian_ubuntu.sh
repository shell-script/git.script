#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function set_fonts_colors(){
	default_fontcolor="\033[0m"
	red_fontcolor="\033[31m"
	info_fontcolor="\033[36m"
	green_backgroundcolor="\033[42;37m"
	red_backgroundcolor="\033[41;37m"
	error_font="${red_fontcolor}[Error]${default_fontcolor}"
	info_font="${info_fontcolor}[Info]${default_fontcolor}"
	check_os
}

function check_os(){
	[ "$EUID" -ne "0" ] && echo -e "${error_font}Please run as root, and retry." && exit 1
	[ -z "$(cat /etc/issue | grep Debian)" ] && [ -z "$(cat /etc/issue | grep Ubuntu)" ] && echo -e "${error_font}The OS isn't supported, please use Debian/Ubuntu, and retry." && exit 1
	change_port
}

function change_port(){
	old_listen_port="$(cat /etc/ssh/sshd_config | grep "Port " | awk -F "#" '{print $NF}' | awk -F "Port " '{print $NF}')"
	ssh_port_linewords="$(cat /etc/ssh/sshd_config | grep "Port ")"
	[ "${ssh_port_linewords}" != "Port ${old_listen_port}" ] && sed -i "s/#Port/Port/g" "/etc/ssh/sshd_config"

	generate_port
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${new_listen_port}" -j ACCEPT > /dev/null
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
	sed -i "s/${old_listen_port}/${new_listen_port}/g" "/etc/ssh/sshd_config"

	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport "${old_listen_port}" -j ACCEPT > /dev/null
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	/etc/init.d/ssh restart > /dev/null
	echo -e "${info_font}Please use the new port [${green_backgroundcolor}${new_listen_port}${default_fontcolor}] to connect to your server."
}

function generate_port(){
	let new_listen_port=$RANDOM+10000
	[ "$(lsof -i:${new_listen_port} | wc -l)" -ne "0" ] || [ "${new_listen_port}" -le "0" ] || [ "${new_listen_port}" -gt "65535" ] && generate_port
}

	set_fonts_colors
