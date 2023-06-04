FROM ubuntu:20.04


# set working directory
WORKDIR /workspace

# install dependencies
RUN apt-get update 
RUN apt-get install -y build-essential  && apt-get install -y wget

# install some basic tools
RUN apt-get install -y git && apt-get install -y vim && apt-get install -y curl && apt-get install -y unzip && apt-get install -y dumb-init 

#install php 8.2 and nginx
RUN apt-get install -y software-properties-common && add-apt-repository ppa:ondrej/php && apt-get update && apt-get install -y php8.2 && apt-get install -y php8.2-fpm

#install nginx and redis
RUN apt-get install -y nginx && apt-get install -y redis-server 

#put php-fpm into nginx conf
RUN sed -i 's/location ~ \\\.php\$ {/location ~ \\\.php\$ {\nfastcgi_pass unix:\/run\/php\/php8.2-fpm.sock;/g' /etc/nginx/sites-available/default

#install php extensions
RUN apt-get install -y php8.2-{apcu,bz2,calendar,cgi-fcgi,Core,ctype,curl,date,dom,exif,fileinfo,filter,ftp,gd,gettext,hash,iconv,intl,json,libxml,mbstring,mysqli,mysqlnd,openssl,pcntl,pcre,PDO,pdo_mysql,pdo_sqlite,Phar,posix,readline,redis,Reflection,session,shmop,SimpleXML,sockets,SPL,sqlite3,standard,sysvmsg,sysvsem,sysvshm,tokenizer,xml,xmlreader,xmlwriter,xsl,Zend OPcache,zip,zlib}

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
ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-r00T!}
ENV MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
ENV MYSQL_USER=${MYSQL_USER:-wordpress}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD:-w0rdpress}

#set mysql root password, and permit it to fail, as it will fail if the password is already set
RUN mysqladmin -u root password ${MYSQL_ROOT_PASSWORD} || true 

#Setup Mysql
RUN mysql_secure_installation -D

#restart mysql
RUN service mysql restart

#create wordpress database, and set permissions, and create wordpress user, and set permissions, and flush privileges. Permit each statement to fail, as it will fail if the database already exists, or the user already exists, or the permissions are already set.
RUN mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" || true && mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';" || true && mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;" || true
 
#install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#install wordpress into default nginx site, if it doesn't exist already
RUN if [ ! -f /var/www/html/index.php ]; then wget https://en-gb.wordpress.org/latest-en_GB.zip && unzip latest-en_GB.zip && mv wordpress/* /var/www/html/ && rm -rf wordpress && rm latest-en_GB.zip; fi

# run server
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD service mysql start && service php8.2-fpm start && nginx -g "daemon off;"