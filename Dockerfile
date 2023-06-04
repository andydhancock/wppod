FROM ubuntu:20.04


# set working directory
WORKDIR /workspace

# install dependencies
RUN apt-get update 
RUN apt-get install -y build-essential  && apt-get install -y wget

#Set timezone to Europe/London
RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime && apt-get install -y tzdata && dpkg-reconfigure --frontend noninteractive tzdata

# install some basic tools
RUN apt-get install -y git && apt-get install -y vim && apt-get install -y curl && apt-get install -y unzip && apt-get install -y dumb-init 

#install php 8.2 and nginx
RUN apt-get install -y software-properties-common && add-apt-repository ppa:ondrej/php && apt-get update && apt-get install -y php8.2 && apt-get install -y php8.2-fpm

#install nginx and redis
RUN apt-get install -y nginx && apt-get install -y redis-server 

#put php-fpm into nginx conf
RUN sed -i 's/location ~ \\\.php\$ {/location ~ \\\.php\$ {\nfastcgi_pass unix:\/run\/php\/php8.2-fpm.sock;/g' /etc/nginx/sites-available/default

#include ./nginx.conf at end of nginx conf
RUN ln -s /workspace/nginx.conf /etc/nginx/conf.d/zzz_custom.conf

#install php extensions
RUN apt-cache search php

RUN apt-get install -y php8.2-{apcu,bz2,calendar,cgi-fcgi,Core,ctype,curl,date,dom,exif,fileinfo,filter,ftp,gd,gettext,hash,iconv,intl,json,libxml,mbstring,mysqli,mysqlnd,openssl,pcntl,pcre,PDO,pdo_mysql,pdo_sqlite,Phar,posix,readline,redis,Reflection,session,shmop,SimpleXML,sockets,SPL,sqlite3,standard,sysvmsg,sysvsem,sysvshm,tokenizer,xml,xmlreader,xmlwriter,xsl,opcache,zip,zlib}

# add source code
COPY . /workspace/

#symlink ./php.ini to /etc/php.d/zzz_custom.ini
RUN ln -s /workspace/php.ini /etc/php.d/zzz_custom.ini

#symlink /var/www/html to /workspace
RUN rm -rf /var/www/html && ln -s /workspace/html /var/www/html

#symlink /var/lib/mysql to /workspace
RUN ln -s /workspace/mysql /var/lib/mysql

#install latest mysql 
RUN apt-get install -y mysql-server && apt-get install -y mysql-client

#set mysql environment variables to default values, if they are not already set
ENV DEFAULT_MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-r00T!}

#set mysql root password, and permit it to fail, as it will fail if the password is already set
RUN mysqladmin -u root password ${DEFAULT_MYSQL_ROOT_PASSWORD} || true 

#Setup Mysql
RUN mysql_secure_installation -D
 
#install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#install wordpress into default nginx site, if it doesn't exist already
RUN if [ ! -f /var/www/html/index.php ]; then wget https://en-gb.wordpress.org/latest-en_GB.zip && unzip latest-en_GB.zip && mv wordpress/* /var/www/html/ && rm -rf wordpress && rm latest-en_GB.zip; fi

# run server
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ./run.sh