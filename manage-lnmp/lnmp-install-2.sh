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
mysql --version &/dev/null
if [ $? -eq 0 ];then
echo "mysql 已安装请检查版本是否正确"
else
#wget https://downloads.mysql.com/archives/get/p/23/file/mysql-boost-5.7.34.tar.gz && tar xvf mysql-boost-5.7.34.tar.gz && cd mysql-5.7.34
tar xvf mysql-boost-5.7.34.tar.gz && cd mysql-5.7.34
yum -y install ncurses ncurses-devel openssl-devel bison gcc gcc-c++ make cmake
groupadd mysql && useradd mysql -g mysql -M -s /sbin/nologin
mkdir -p /usr/local/mysql
cmake . \
-DWITH_BOOST=boost/boost_1_59_0/ \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DSYSCONFDIR=/etc \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DINSTALL_MANDIR=/usr/share/man \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DDEFAULT_CHARSET=utf8 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_READLINE=1 \
-DWITH_SSL=system \
-DWITH_EMBEDDED_SERVER=1 \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1
 make && make install 
cd /usr/local/mysql && chown -R mysql.mysql .
/usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql
cat > /etc/my.cnf<<EOF
[mysqld]
basedir=/usr/local/mysql #指定安装目录
datadir=/usr/local/mysql/data #指定数据存放目录
EOF
cd /usr/local/mysql
 ./bin/mysqld_safe --user=mysql &
\cp support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
systemctl start mysqld
/usr/local/mysql/bin/mysqladmin -u root  password '${dbpasswd}'
echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile && source /etc/profile
fi
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
mysql
