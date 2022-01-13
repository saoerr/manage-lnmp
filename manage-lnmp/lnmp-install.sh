#!/bin/bash
source(){
systemctl stop firewalld
setenforce 0
yum -y install wget 
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
}
nginx(){
wget http://nginx.org/packages/centos/7/x86_64/RPMS/nginx-1.18.0-1.el7.ngx.x86_64.rpm
yum -y install nginx-1.18.0-1.el7.ngx.x86_64.rpm
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
mv  /etc/nginx/conf.d/default.conf  /etc/nginx/conf.d/default.conf.bak
cp /root/default.conf /etc/nginx/conf.d/
systemctl start  nginx &&  systemctl enable  nginx
}
mysql(){
rpm -Uvh  http://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
yum -y install mysql-community-server
systemctl start mysqld && systemctl enable mysqld  && systemctl daemon-reload
oldpasswd=`grep 'temporary password' /var/log/mysqld.log | awk   '{print  $11}'`
mysqladmin -uroot -p$oldpasswd password Haoqiang@123
}
php(){
yum -y  install \
https://repo.ius.io/ius-release-el7.rpm \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install php70w-devel php70w.x86_64 php70w-cli.x86_64 php70w-common.x86_64 php70w-gd.x86_64 php70w-ldap.x86_64 php70w-mbstring.x86_64 php70w-mcrypt.x86_64  php70w-pdo.x86_64   php70w-mysqlnd  php70w-fpm php70w-opcache php70w-pecl-redis php70w-pecl-mongodb
echo "<?php echo phpinfo(); ?>">/usr/share/nginx/html/phpinfo.php
systemctl start php-fpm && systemctl enable php-fpm
}
install-lnmp(){
source
nginx
mysql
php
}
install-lnmp
