FROM nvidia/cuda:11.6.2-base-ubuntu20.04


# set working directory
WORKDIR /workspace
USER root 

# install dependencies
RUN apt-get update 
RUN apt-get install -y build-essential  && apt-get install -y wget

#Set timezone to Europe/London
RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime && apt-get install -y tzdata && dpkg-reconfigure --frontend noninteractive tzdata

# install some basic tools
RUN apt-get install -y git && apt-get install -y vim && apt-get install -y curl && apt-get install -y unzip && apt-get install -y dumb-init 

#remove default php 
RUN apt-get remove -y php*

#remove apache2
RUN apt-get remove -y apache2

RUN apt-get upgrade -y
#install php 8.2 and nginx
RUN apt-get install -y software-properties-common && add-apt-repository ppa:ondrej/php && add-apt-repository ppa:ondrej/nginx && apt-get update && apt-get install -y php8.2 && apt-get install -y php8.2-fpm

#install nginx and redis
RUN apt-get install -y nginx && apt-get install -y redis-server 

#install ssl for nginx
RUN apt-get install -y openssl && apt-get install -y ssl-cert
#setup ssl
RUN mkdir /etc/nginx/ssl
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"

#set default site into nginx.conf
RUN rm /etc/nginx/sites-available/default
COPY ./default /etc/nginx/sites-available/default


#install certbot
RUN apt-get install -y certbot python3-certbot-nginx

#put php-fpm into nginx.conf
COPY ./php-fpm.conf /etc/nginx/conf.d/php-fpm.conf



#include ./nginx.conf at end of nginx conf
RUN touch /workspace/nginx.conf
RUN ln -s /workspace/nginx.conf /etc/nginx/conf.d/zzz_custom.conf

RUN apt-cache search php8.2
RUN apt-get update 

RUN apt-get install --fix-missing -y php8.2-amqp php8.2-ast php8.2-bcmath php8.2-bz2 php8.2-cgi php8.2-cli php8.2-common php8.2-curl php8.2-dba php8.2-decimal php8.2-dev php8.2-ds php8.2-enchant php8.2-excimer php8.2-fpm php8.2-gd php8.2-gearman php8.2-gmp php8.2-gnupg php8.2-grpc php8.2-http php8.2-igbinary php8.2-imagick php8.2-imap php8.2-inotify php8.2-interbase php8.2-intl php8.2-ldap php8.2-libvirt-php php8.2-lz4 php8.2-mailparse php8.2-maxminddb php8.2-mbstring php8.2-mcrypt php8.2-memcache php8.2-memcached php8.2-mongodb php8.2-msgpack php8.2-mysql php8.2-oauth php8.2-odbc php8.2-opcache php8.2-pcov php8.2-pgsql php8.2-phpdbg php8.2-pinba php8.2-protobuf php8.2-ps php8.2-pspell php8.2-psr php8.2-raphf php8.2-rdkafka php8.2-readline php8.2-redis php8.2-rrd php8.2-smbclient php8.2-snmp php8.2-soap php8.2-solr php8.2-sqlite3 php8.2-ssh2 php8.2-stomp php8.2-swoole php8.2-sybase php8.2-tideways php8.2-tidy php8.2-uopz php8.2-uploadprogress php8.2-uuid php8.2-vips php8.2-xdebug php8.2-xhprof php8.2-xml php8.2-xmlrpc php8.2-xsl php8.2-yaml php8.2-zip php8.2-zmq php8.2-zstd
# add source code
COPY . /workspace/
RUN mkdir /var/scripts/
COPY run.sh /var/scripts/run.sh

#symlink ./php.ini to /etc/php.d/zzz_custom.ini
RUN touch /workspace/php.ini
RUN ln -s /workspace/php.ini /etc/php/8.2/fpm/conf.d/zzz_custom.ini

RUN mkdir /workspace/html
#symlink /var/www/html to /workspace
RUN rm -rf /var/www/html && ln -s /workspace/html /var/www/html

RUN mkdir /workspace/mysql

#symlink /var/lib/mysql to /workspace
RUN ln -s /workspace/mysql /var/lib/mysql

#install latest mysql 
RUN apt-get install -y mysql-server && apt-get install -y mysql-client	
 
#install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#install wordpress into default nginx site, if it doesn't exist already
RUN if [ ! -f /var/www/html/index.php ]; then wget https://en-gb.wordpress.org/latest-en_GB.zip && unzip latest-en_GB.zip && mv wordpress/* /var/www/html/ && rm -rf wordpress && rm latest-en_GB.zip; fi

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

RUN chmod -R 777 /var/www/html
RUN chmod 777 /workspace/customrun.sh
RUN chmod +x /var/scripts/run.sh

#install bash
RUN apt-get install -y bash

RUN ls -la /workspace
# run server
CMD bash -c /workspace/customrun.sh