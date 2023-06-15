#!/bin/bash

rm -rf /workspace/mysql
rm -rf /workspace/html
rm -rf /root/.my.cnf
rm -rf /workspace/mysqlsecureinstallation.log
cd /workspace/wppod
git pull
cp ./run.sh /var/scripts/run.sh
killall -9 nginx