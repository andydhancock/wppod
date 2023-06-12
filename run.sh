#set mysql environment variables to default values, if they are not already set
export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-r00T!}
export MYSQL_DATABASE=${MYSQL_DATABASE:-"wordpress"}
export MYSQL_USER=${MYSQL_USER:-"wordpress"}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-"w0rdpr3sS!"}

echo "Starting mysql"
service mysql restart
#if /var/lib/mysql is empty, then run mysql_install_db
if [ -z "$(ls -A /var/lib/mysql)" ]; then
	echo "initializing mysql database"
	mysql_install_db --insecure --user=mysql --datadir=/var/lib/mysql
fi
#if mysqlsecureinstallation.log doesn't exist, then run mysql_secure_installation
if [ ! -f /workspace/mysqlsecureinstallation.log ]; then
	echo "running mysql_secure_installation"
	#set default mysql root password
	mysqladmin -u root password ${MYSQL_ROOT_PASSWORD}

	#set mysql root password in /root/.my.cnf
	echo "[client]\nuser=root\npassword=${MYSQL_ROOT_PASSWORD}" > /root/.my.cnf

	#run mysql_secure_installation.sql
	mysql -uroot < mysql_secure_installation.sql > /workspace/mysqlsecureinstallation.log

fi

echo "Creating wordpress database and user"
#create wordpress database, and set permissions, and create wordpress user, and set permissions, and flush privileges. Permit each statement to fail, as it will fail if the database already exists, or the user already exists, or the permissions are already set.
#mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_PASSWORD}';" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;" || true
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" || true && mysql -u root -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';" || true && mysql -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';" || true && mysql -u root -e "FLUSH PRIVILEGES;" || true

if [ ! -f /var/www/html/index.php ]; then 
	wget https://en-gb.wordpress.org/latest-en_GB.zip && unzip latest-en_GB.zip && mv wordpress/* /var/www/html/ && rm -rf wordpress && rm latest-en_GB.zip; 
fi

#if /var/www/html/wp-config.php doesn't exist, then create it.
if [ ! -f /var/www/html/wp-config.php ]; then
	echo "Creating wp-config.php"
	#copy wp-config-sample.php to wp-config.php	
	cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
	#set database name in wp-config.php
	sed -i "s/database_name_here/${MYSQL_DATABASE}/" /var/www/html/wp-config.php
	#set database user in wp-config.php
	sed -i "s/username_here/${MYSQL_USER}/" /var/www/html/wp-config.php
	#set database password in wp-config.php
	sed -i "s/password_here/${MYSQL_PASSWORD}/" /var/www/html/wp-config.php
	#change localhost to 127.0.0.1
	sed -i "s/localhost/127.0.0.1/" /var/www/html/wp-config.php
	#set authentication unique keys and salts
	sed -i "s/put your unique phrase here/$(curl -s https://api.wordpress.org/secret-key/1.1/salt)/" /var/www/html/wp-config.php
	
fi


echo "Starting php8.2-fpm"
service php8.2-fpm start

echo "Starting nginx"
nginx -g "daemon off;"