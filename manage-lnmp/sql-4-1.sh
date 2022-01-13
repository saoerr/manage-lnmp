#!/bin/bash
echo -n >ip-group.list
ipnum=`mysql -uroot -pHaoqiang@123 -e " select * from first.one ;" 2>/dev/null | awk '{print $1}' | awk 'NR>1' |wc -l`
for i in `seq $ipnum`
do
mysql -uroot -pHaoqiang@123 -e " select * from first.one ;" 2>/dev/null | awk 'NR>1' | sed -n "${i}p" |awk '{print $1 "\t"  $NF}' >> ip-group.list
done
mysql -uroot -pHaoqiang@123 -e " select * from first.apply_serves ;" 2>/dev/null |awk 'NR>1' | awk '{print $2 $3}' >oper-serverid.list
