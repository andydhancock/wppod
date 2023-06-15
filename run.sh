#set mysql environment variables to default values, if they are not already set
export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-r00T!}
export MYSQL_DATABASE=${MYSQL_DATABASE:-"wordpress"}
export MYSQL_USER=${MYSQL_USER:-"wordpress"}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-"w0rdpr3sS!"}

cp /workspace/mysqld.cnf /etc/mysql/mysql.conf.d/zz-mysqld.cnf

#if /var/lib/mysql is empty, then run mysql_install_db
if [ -z "$(ls -A /workspace/mysql)" ]; then
	echo "initializing mysql database"
	mysqld --initialize-insecure --user=root --basedir=/usr --datadir=/workspace/mysql > /workspace/mysql.log 2>&1

fi

echo "Starting mysql"
service mysql restart

#if mysqlsecureinstallation.log doesn't exist, then run mysql_secure_installation
if [ ! -f /workspace/mysqlsecureinstallation.log ]; then
	echo "running mysql_secure_installation"
	#set default mysql root password
	mysqladmin -u root password ${MYSQL_ROOT_PASSWORD} > /workspace/mysqladmin.log 2>&1

	#set mysql root password in /root/.my.cnf
	echo -e "[client]\nuser=root\npassword=${MYSQL_ROOT_PASSWORD}" > /root/.my.cnf

	#run mysql_secure_installation.sql
	mysql -uroot < /workspace/wppod/mysql_secure_installation.sql > /workspace/mysqlsecureinstallation.log

fi

echo "Creating wordpress database and user"
#create wordpress database, and set permissions, and create wordpress user, and set permissions, and flush privileges. Permit each statement to fail, as it will fail if the database already exists, or the user already exists, or the permissions are already set.
#mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_PASSWORD}';" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;" || true
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" || true && mysql -u root -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';" || true && mysql -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';" || true && mysql -u root -e "FLUSH PRIVILEGES;" || true

if [ ! -f /workspace/html/index.php ]; then 
	echo "Downloading wordpress"
	#if /workspace/html/ doesn't exist, create it
	if [ ! -d /workspace/html/ ]; then
		mkdir -p /workspace/html/
		chmod 755 /workspace/html/
		chown www-data:www-data /workspace/html/
	fi

	wget -q https://en-gb.wordpress.org/latest-en_GB.zip && unzip -q -o latest-en_GB.zip && mv wordpress/* /workspace/html/ && rm -rf wordpress && rm latest-en_GB.zip ; 
fi

#if /workspace/html/wp-config.php doesn't exist, then create it.
if [ ! -f /workspace/html/wp-config.php ]; then
	echo "Creating wp-config.php"
	#copy wp-config-sample.php to wp-config.php	
	cp /workspace/html/wp-config-sample.php /workspace/html/wp-config.php
	#set database name in wp-config.php
	sed -i "s/database_name_here/${MYSQL_DATABASE}/" /workspace/html/wp-config.php
	#set database user in wp-config.php
	sed -i "s/username_here/${MYSQL_USER}/" /workspace/html/wp-config.php
	#set database password in wp-config.php
	sed -i "s/password_here/${MYSQL_PASSWORD}/" /workspace/html/wp-config.php
	#change localhost to 127.0.0.1
	sed -i "s/localhost/127.0.0.1/" /workspace/html/wp-config.php
	#set authentication unique keys and salts
	sed -i "s/put your unique phrase here/$(curl -s https://api.wordpress.org/secret-key/1.1/salt)/" /workspace/html/wp-config.php

	#set WPLANG to en_GB, add line after the line which contains "Add any custom values' if it doesn't exist
	if grep -q "WPLANG" /workspace/html/wp-config.php; then
		sed -i "s/define('WPLANG', '');/define('WPLANG', 'en_GB');/" /workspace/html/wp-config.php
	else
		sed -i "/Add any custom values/a define('WPLANG', 'en_GB');\$locale = 'en_GB';define( 'WP_MEMORY_LIMIT', '256M' );" /workspace/html/wp-config.php
	fi
	

	#set WP_DEBUG to true, add line after the line which contains "Add any custom values' if it doesn't exist
	if grep -q "WP_DEBUG" /workspace/html/wp-config.php; then
		sed -i "s/define( 'WP_DEBUG', false );/define('WP_DEBUG', true);/" /workspace/html/wp-config.php
	else
		sed -i "/Add any custom values/a define('WP_DEBUG', true);" /workspace/html/wp-config.php
	fi

	#set WP_DEBUG_LOG to true, add line after the line which contains "Add any custom values' if it doesn't exist
	if grep -q "WP_DEBUG_LOG" /workspace/html/wp-config.php; then
		sed -i "s/define('WP_DEBUG_LOG', false);/define('WP_DEBUG_LOG', '/workspace/debug.log');/" /workspace/html/wp-config.php
	else
		sed -i "/Add any custom values/a define('WP_DEBUG_LOG', '/workspace/debug.log');" /workspace/html/wp-config.php
	fi



fi

cp /workspace/php.ini /etc/php/8.2/fpm/conf.d/zzz_custom.ini
echo "Starting php8.2-fpm"
service php8.2-fpm start

cp /workspace/nginx.conf /etc/nginx/conf.d/zzz_custom.conf
echo "Starting nginx"
nginx -g "daemon off;"