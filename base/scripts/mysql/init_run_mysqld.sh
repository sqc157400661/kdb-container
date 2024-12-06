#!/bin/bash

# create dirs
DIRS=('/u01/data' '/u01/etc' '/u01/log' '/u01/socket' '/u01/tmp' '/u01/mysql-files' '/u01/certs')
for DIRECTORY in "${DIRS[@]}"
do
    if [ ! -d "$DIRECTORY" ]; then
        echo "Creating dir $DIRECTORY"
        mkdir "$DIRECTORY"
    fi
    echo "chown $DIRECTORY to mysql"
    chown mysql:mysql "$DIRECTORY"
done

# change /u01 owner
CUR_UNAME="$(stat -c '%U' /u01)"
if [ "x${CUR_UNAME}" = "xmysql" ]; then
    echo "/u01 belongs to user $CUR_UNAME"
else
    echo "/u01 belongs to $CUR_UNAME , chown to mysql"
    chown mysql:mysql /u01 -R
fi

# check datadir and init
if [ -z "$(ls -A /u01/data)" ]; then
    echo "/u01/data is empty, initialize the dir"
    # init 
    mysqld --initialize-insecure --user=mysql --datadir=/u01/data
else
    echo "/u01/data is not empty, not initialize the dir"
fi

cp /etc/config/my.cnf /u01/etc/
# start msyqld
# socket and port flags are required by agent
mysqld --user=mysql --socket=/u01/socket/mysqld.sock --port=3306 --pid-file=/u01/socket/mysqld.pid