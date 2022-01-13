#!/bin/bash
dbpasswd=Haoqiang@123
cur_dir=$(pwd)
source(){
systemctl stop firewalld
setenforce 0
yum -y install wget 
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
}
nginx_install(){
#wget http://nginx.org/download/nginx-1.21.3.tar.gz
nginx -v  &>/dev/null
if [ $? -eq 0 ];then
echo "nginx已经部署，请核对版本"
else
yum -y install gcc gcc-c++   pcre pcre-devel gd-devel   openssl openssl-devel  zlib zlib-devel
mkdir  /var/log/nginx
groupadd nginx
useradd -s /sbin/nologin -g nginx nginx
tar xvf ${cur_dir}/nginx-1.20.1.tar.gz -C /usr/local
mv /usr/local/nginx-1.20.1 /usr/local/nginx
cd /usr/local/nginx
./configure \
--prefix=/usr/local/nginx \
--group=nginx \
--user=nginx \
--sbin-path=/usr/local/nginx/sbin/nginx \
--conf-path=/usr/local/nginx/conf/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/tmp/nginx/client_body \
--http-proxy-temp-path=/tmp/nginx/proxy \
--http-fastcgi-temp-path=/tmp/nginx/fastcgi \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/lock/nginx \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_gzip_static_module \
--with-pcre \
--with-http_realip_module \
--with-stream
make
make install
\cp ${cur_dir}/nginx /etc/init.d/
chmod +x /etc/init.d/nginx
systemctl daemon-reload
chkconfig --add nginx
chkconfig nginx on
mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
cp ${cur_dir}/nginx.conf /usr/local/nginx/conf/
systemctl start nginx
ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx
fi
}
mysql_install(){
mysql --version &>/dev/null
if [ $? -eq 0 ];then
echo "mysql 已安装请检查版本是否正确"
else
tar xvf ${cur_dir}/mysql-boost-5.7.34.tar.gz 
cd ${cur_dir}/mysql-5.7.34
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
\cp support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
systemctl start mysqld
/usr/local/mysql/bin/mysqladmin -u root  password "${dbpasswd}"
ln -sf /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -sf /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
ln -sf /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
ln -sf /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
ln -sf /usr/local/mysql/bin/mysqlcheck /usr/bin/mysqlcheck
ln -sf /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin
fi
}
php_install(){
php -v  &>/dev/null
if [ $? -eq 0 ];then
echo "php已部署，请检查版本"
else
yum -y  install \
https://repo.ius.io/ius-release-el7.rpm \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install php70w-devel php70w.x86_64 php70w-cli.x86_64 php70w-common.x86_64 php70w-gd.x86_64 php70w-ldap.x86_64 php70w-mbstring.x86_64 php70w-mcrypt.x86_64  php70w-pdo.x86_64   php70w-mysqlnd  php70w-fpm php70w-opcache php70w-pecl-redis php70w-pecl-mongodb
echo "<?php echo phpinfo(); ?>">/usr/local/nginx/html/phpinfo.php
systemctl start php-fpm && systemctl enable php-fpm
fi
}
trap "echo   'lnmp 部署完成' " EXIT
mysql_install
nginx_install
php_install

