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
echo "当前可用更新包"
ls /opt/web/
read -p "请输入要上传更新的包名: " package
ansible-playbook /opt/ansible/release_manage.yaml -e "host=$char path=/opt/web/${package}"
echo -e " \n 完成 \n"
;;
all)
echo "当前可用更新包"
ls /opt/web/
read -p "请输入要上传更新的包名: " package
ansible-playbook /opt/ansible/release_manage.yaml -e "host=ops path=/opt/web/${package}"
echo -e " \n 完成 \n"
;;
esac
break
done
}
release_down(){
while :
do
h=1
echo "请选择机器"
echo "-----------------------"
for i in `cat /etc/ansible/hosts | awk 'NR >1'`
do
echo "$i		$h"
let ++h
done
echo "返回			q"
echo "------------------------"
read -p "请输入选项: " char
case $char in
q)
break
;;
esac
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
