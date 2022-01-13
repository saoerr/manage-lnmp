#!/bin/bash
#mysql-env
user=root
passwd=Haoqiang@123
database=first
table=one
table_2=apply_serves
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
	ls *-free.list -l &>/dev/null
	if [ $? -eq 0 ];then
	file_name=`ls *.list -l |awk '{print $9}'`
	for j in $file_name
	do
	echo -n > $j
	done
	fi
}
comput_ip(){
	#把port_group组里面空闲的格子和ip对应起来
	fields_num=`mysql -u$user -p$passwd -h$host -e "select * from $database.$table;" 2>/dev/null |head -n1 |awk  '{$1=""; print }'|awk  '{$NF="";  print }'`  
	max_a=`mysql -u$user -p$passwd -h$host -e " select * from $database.$table_2 ;" 2>/dev/null |awk 'NR>1' | grep a |awk '{print $3}' | sort -r | head -n1`
	max_b=`mysql -u$user -p$passwd -h$host  -e " select * from $database.$table_2 ;" 2>/dev/null |awk 'NR>1' | grep b |awk '{print $3}' | sort -r | head -n1`
		for i in $fields_num
		do
	#awk 中引用外部变量 “  awk '{print $1 " '${i}' " $NF}'`  ” 使用 “ ‘$’  ”
	free_port=`mysql -u$user -p$passwd -h$host -e "select * from $database.$table where $i=' ';" 2>/dev/null | awk 'NR>1'| awk '{print $1 " '${i}' " $NF}'`
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
	
	group_list=`cat free_ip.list | awk '{print $3}'`
	
	s=1	#$s 是来查看sed对应的行
	f=1	#$f 是和$max_a做比较
	g=1	#$g 是和$max_b作比较
	for n in $group_list
	do
	sed_list=`cat free_ip.list  | sed -n "${s}p"`
	let s=++s
	if [ "$n" == "a" ];then
		if [ $f -le $max_a ];then
		echo "$sed_list $f" >>last-need.list
		let f=++f
#		else  echo "$sed_list"  >>last-need.list	#输出所有的到文件
		fi
	elif [ "$n" == "b" ];then
		if [ $g -le $max_b ];then
	        echo "$sed_list $g" >>last-need.list
	        let g=++g
#		else  echo "$sed_list"  >>last-need.list
		fi
	fi
	done

}
#检查输入的数字是否合理，并且输出正常的结果
num_check(){
	free_ipnum=`cat  last-need.list |wc -l`
        if [ $free_ipnum -ge $num ];then
        echo "success"
        echo "-------------------"
        cat last-need.list  | shuf |head -n$num
        else
        echo "error"
        echo "-------------------"
        echo -e "${blue}ip_sum=$free_ipnum ${clean}"
        fi
}
while :
do
echo "请输入需要的数量"
read  num
clear_file
comput_ip
num_check
trap "echo -e  '\n ${yellow} Good Bye ${clean}' " EXIT
done
