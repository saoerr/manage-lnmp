#!/bin/bash
host_list=`cat /etc/ansible/hosts`
#color
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
pink='\e[1;35m'
clean='\e[0m'

manage_menu(){
trap "echo -e  '\n ${yellow} Good Bye ${clean}' " EXIT
cat <<-EOF
------------------------
机器列表		1
环境部署		2
版本迭代		3
环境清理		4
退出			q
------------------------

EOF

}
release_menu(){
cat <<-EOF
请选择
------------------------
版本升级		1
版本回退		2
返回			q

------------------------

EOF
}
release_up(){
while :
do
echo "请选择机器"
echo "-----------------------"
	for i in `cat /etc/ansible/hosts | awk 'NR >1'`
	do 
	echo "$i 		"
	done
echo "全部部署		all"
echo "返回			q"
echo "------------------------"
	read -p "请输入选项: " char
	case $char in 
	q)
	break
	;;
	*.*.*.*)
	echo -n >/opt/list/up-release.list
	ansible $char -m shell -a "ls /opt/html/" >/opt/list/release.txt
	ansible $char -m shell -a "ls -l /usr/local/nginx/html/wp" >/opt/list/release_1.txt
now_release=`cat /opt/list/release_1.txt  | awk 'NR>1' |awk -F '/' '{print $NF}'`
#now_release=`cat /opt/list/release.txt  | awk '{print $1}' | sort -r | head -n1`
#换成数字版本比较
now_release2=`cat /opt/list/release.txt  | awk '{print $1}' | sort -r | head -n1 |awk -F'-' '{print $2}' | awk -F'.' '{print $1 $2}'`
op1_release=`ls web | sort -r | awk -F'-' '{print $2}' | awk -F'.' '{print $1 $2}'`
j=1
if [ ! $now_release2  ];then 
echo -e "当前机器没有部署版本 \n当前可用更新包: \n$(ls /opt/web)"
	read -p "请输入要上传更新的包名(q 返回): " package
	if [ $package == q ];then
	break
	fi
else
	for i in $op1_release
	do
		if [ "$i" -gt "$now_release2"  ];then
		ls web | sort -r  | sed -n "${j}p" >> /opt/list/up-release.list
		let j=++j
		else break
		fi
	done
update=$(cat /opt/list/up-release.list)
	if [[ ! $update  ]];then
		echo -e "当前机器版本为：${green} $now_release ${clean} \n最新版本已安装，可以尝试版本回滚 "
		break
		else
		echo -e "当前机器版本为：${green} $now_release ${clean} \n当前可用更新包: \n$(cat /opt/list/up-release.list)"

	fi
	read -p "请输入要上传更新的包名(q 返回): " package
		if [ $package == q ];then
			break
		fi
fi
unzip_packagename=`echo "$package" |awk -F'.zip' '{print $1}'`
ansible-playbook /opt/ansible/update_release_manage.yaml -e "host=$char  path=/opt/web/${package}  new_path=/opt/html/$unzip_packagename"
echo -e " \n 完成 \n"
;;
all)
echo "当前可用更新包"
ls /opt/web/
read -p "请输入要上传更新的包名(q 返回): " package
#ansible-playbook /opt/ansible/release_manage.yaml -e "host=ops path=/opt/web/${package}"
	if [ $package == q  ];then
		break
	fi
echo -e " \n 完成 \n"
;;
esac
break
done
}
release_down(){
while :
do
	echo "请选择机器"
	echo "-----------------------"
		for i in `cat /etc/ansible/hosts | awk 'NR >1'`
			do
			echo "$i		"
		done
	echo "返回			q"
	echo "------------------------"
	read -p "请输入选项: " char
		case $char in
		q)
		break
		;;
		*.*.*.*)
		ansible 192.168.153.12 -m shell -a "ls -l /usr/local/nginx/html/wp" >/dev/null
			if [ $?  -eq 0 ];then
				ansible $char -m shell -a "ls /opt/html/" >/opt/list/release.txt
				ansible $char -m shell -a "ls -l /usr/local/nginx/html/wp" >/opt/list/release_1.txt
				now_release=`cat /opt/list/release_1.txt  | awk 'NR>1' |awk -F '/' '{print $NF}'`
				#换成数字版本比较
				now_release2=`cat /opt/list/release.txt |awk 'NR>1' | awk '{print $1}' | sort -r | head -n1 `
				#可以回滚的版本
				rollback_list=`cat /opt/list/release.txt |awk 'NR>1' | grep -v $now_release `
				#op1_release=`ls web | sort -r | awk -F'-' '{print $2}' | awk -F'.' '{print $1 $2}'`
						if [ ! $now_release2  ];then
							echo -e "当前机器没有部署版本 \n请先更新版本"
							else
							echo -e "当前机器版本为：${green} $now_release ${clean} \n可回滚版本: \n$rollback_list"
						fi
				read -p "请输入要回滚的包名(q 返回): " package
					if [ $package == q  ];then
						break
					fi
				rollback_packagename=`echo "$package" |awk -F'.zip' '{print $1}'`
				ansible-playbook /opt/ansible/rollback_release_manage.yaml -e "host=$char    new_path=/opt/html/$rollback_packagename"
				echo -e " \n 完成 \n"
				else echo -e "当前机器没有部署版本 \n请先更新版本"
			fi
		;;
		esac
		break
done
}

ip_list(){
echo -e "\n"
cat /etc/ansible/hosts | awk 'NR >1'
echo -e "\n"
}
install_env(){
while :
do
	k=1
	echo "请选择机器或者机器组"
	echo "-----------------------"
		for i in `cat /etc/ansible/hosts | awk 'NR >1'`
		do
		echo "$i		$k"
		let ++k
		done
	echo "全部部署		all"
	echo "返回			q"
	echo "------------------------"
	read -p "请输入选项: " char
		case $char in
		[0-9] |[0-9][0-9] |[0-9][0-9][0-9])
		ip_num=`cat /etc/ansible/hosts | awk 'NR >1'  |wc -l`
			if [ $char -le $ip_num ];then
				ip=`cat /etc/ansible/hosts | awk 'NR >1' |sed -n "${char}p"`
				ansible -vv $ip -m shell -a "hostname"
				ansible -vv $ip -m copy -a "src=/opt/lnmp dest=/opt"
				ansible -vv $ip -m shell -a "cd /opt/lnmp/ && sh -x /opt/lnmp/lnmp-install.sh"
			else 
				echo "error num"
			fi
			;;
			all)
			host=`cat -n  /etc/ansible/hosts   | grep "\["  |awk -F [ '{print  $2}' |  awk -F ] '{print  $1}'`
			ansible -vv $host -m shell -a "hostname"
			ansible -vv $host -m copy -a "src=/opt/lnmp dest=/opt"
			ansible -vv $host -m shell -a "cd /opt/lnmp/ && sh -x /opt/lnmp/lnmp-install.sh"
			;;
			q)
			break
			;;
			esac
done

}
clean_env(){
while :
do
echo "请选择机器或者机器组"
echo "-----------------------"
	for i in `cat /etc/ansible/hosts | awk 'NR >1'`
	do
	echo "$i                "
	done
echo "-----------------------"
echo "全部清理		all"
echo "返回			q"
echo "------------------------"
read -p "请输入选项: " char
	if [ $char == all ];then
		ansible-playbook  ansible/clean_env.yaml  -e "host=ops" -C 
	elif [ $char == q ];then
		break
	else
		ansible-playbook  ansible/clean_env.yaml  -e "host=${char}" -C
	fi
done
}
while :
do
	manage_menu
	read -p "请输入选项：" num
	case  "$num" in
		1)
		ip_list
		;;
		2)
		install_env
	
	
		echo ""
		;;
		
		3)
		while :
		do
		release_menu
			read -p "请输入选项：" num_2
			case $num_2 in
			q)
			break
			;;
			1)
			release_up
			;;
			2)
			release_down
			;;
			esac
			done
			echo ""
		;;
		4)
		clean_env
		;;
		q)
		exit 
		;;
		*)
		echo -e "${red} Please enter the numbers in the list ${clean}"
		echo ""
		esac
done
