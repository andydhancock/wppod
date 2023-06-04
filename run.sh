#!/usr/bin/dumb-init /bin/sh

#set mysql environment variables to default values, if they are not already set
export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-${DEFAULT_MYSQL_ROOT_PASSWORD}}
export MYSQL_DATABASE=${MYSQL_DATABASE:-"wordpress"}
export MYSQL_USER=${MYSQL_USER:-"wordpress"}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-"w0rdpr3sS!"}

service mysql start

#create wordpress database, and set permissions, and create wordpress user, and set permissions, and flush privileges. Permit each statement to fail, as it will fail if the database already exists, or the user already exists, or the permissions are already set.
mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';" || true && mysql -u root -p${DEFAULT_MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;" || true

service php8.2-fpm start

nginx -g "daemon off;"