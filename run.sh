#!/bin/sh

#set mysql environment variables to default values, if they are not already set
export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-r00T!}
export MYSQL_DATABASE=${MYSQL_DATABASE:-"wordpress"}
export MYSQL_USER=${MYSQL_USER:-"wordpress"}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-"w0rdpr3sS!"}

service mysql start
#if /var/lib/mysql is empty, then run mysql_install_db
if [ -z "$(ls -A /var/lib/mysql)" ]; then
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi
#if mysqlsecureinstallation.log doesn't exist, then run mysql_secure_installation
if [ ! -f /workspace/mysqlsecureinstallation.log ]; then
	#set default mysql root password
	mysqladmin -u root password ${MYSQL_ROOT_PASSWORD}

	#set mysql root password in /root/.my.cnf
	echo "[client]\nuser=root\npassword=${MYSQL_ROOT_PASSWORD}" > /root/.my.cnf

	#run mysql_secure_installation
	mysql_secure_installation -D ${MYSQL_DATABASE} -u root -p${MYSQL_ROOT_PASSWORD} > /workspace/mysqlsecureinstallation.log

fi

#create wordpress database, and set permissions, and create wordpress user, and set permissions, and flush privileges. Permit each statement to fail, as it will fail if the database already exists, or the user already exists, or the permissions are already set.
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;" || true

service php8.2-fpm start

nginx -g "daemon off;"