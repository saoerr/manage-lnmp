#!/bin/bash
#mysql-env
user=root
passwd=Haoqiang@123
database=first
table=one
host=127.0.0.1
#color
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
pink='\e[1;35m'
clean='\e[0m'

#清空之前生成的文件内容
clear_file(){
	ls *-free.list -l >/dev/null 2>/dev/null
	if [ $? -eq 0 ];then
	file_name=`ls *-free.list -l |awk '{print $9}'`
	for j in $file_name
	do
	echo -n > $j
	done
	fi
}
clear_file
letter_group=`cat free_ip.list  | awk '{print $3}'`
oper_id=`mysql -uroot -pHaoqiang@123 -e " select * from first.apply_serves ;" 2>/dev/null |awk 'NR>1' | awk '{print $2 $3}'`
#cat free_ip.list  | awk '{print $3}'
#把port_group组里面空闲的格子和ip对应起来
	fields_num=`mysql -u$user -p$passwd -h$host -e "select * from $database.$table;" 2>/dev/null |head -n1 |awk  '{$1=""; print }'|awk  '{$NF="";  print }'`  
	for i in $fields_num
	do
#echo "$i"
#awk 中引用外部变量 “  awk '{print $1 " '${i}' " $NF}'`  ” 使用 “ ‘$’  ”
	free_port=`mysql -u$user -p$passwd -h$host -e "select * from $database.$table where $i=' ';" 2>/dev/null | awk 'NR>1'| awk '{print $1 " '${i}' " $NF}'`
#	echo "$free_port"
	#for k in $free_port
	#do
	# [[]]  比 [] 通用性更强 容错性也更好  可以解决 too many arguments 报错
	if [[ ! $free_port ]]; 
	then 
	echo -n >>$i-free.list
	else
	echo  "$free_port" >>$i-free.list
	fi
	#done
	done
	file_name=`ls *-free.list -l |awk '{print $9}'`
	cat $file_name  | sort -t. -k4 -n|uniq >free_ip.list
#echo "$letter_group"
#echo "$oper_id"
mysql -uroot -pHaoqiang@123 -e " select * from first.apply_serves ;" 2>/dev/null |awk 'NR>1' | awk '{print $2 " " $3}' > oper-serverid.list

#group_oper=`mysql -uroot -pHaoqiang@123 -e " select * from first.apply_serves ;" 2>/dev/null |awk 'NR>1' | awk '{print $2}'| uniq`
group_list=`cat free_ip.list | awk '{print $3}'`

s=1
f=1
g=1
for n in $group_list
do
sed_num=`cat free_ip.list | awk '{print $3}' | sed -n "${s}p"`
sed_list=`cat free_ip.list  | sed -n "${s}p"`
#echo "$sed_num"
let s=++s
#echo "$s"
#
#	for m in $group_oper
#	do
#		if [ $n == $m ];then
#		echo "$n  $m"
#       		echo "$n $sed_char"
#		fi
#
#	done
max_a=`mysql -uroot -pHaoqiang@123 -e " select * from first.apply_serves ;" 2>/dev/null |awk 'NR>1' | grep a |awk '{print $3}' | sort -r | head -n1`
max_b=`mysql -uroot -pHaoqiang@123 -e " select * from first.apply_serves ;" 2>/dev/null |awk 'NR>1' | grep b |awk '{print $3}' | sort -r | head -n1`
if [ "$n" == "a" ];then
	if [ $f -le $max_a ];then
	echo "$sed_list $f"
	let f=++f
	fi
elif [ "$n" == "b" ];then
	if [ $g -le $max_b ];then
        echo "$sed_list $g"
        let g=++g
	fi
fi


done
