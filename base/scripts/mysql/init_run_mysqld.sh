#!/bin/bash

# create dirs
DIRS=('/kdbdata/data' '/kdbdata/etc' '/kdbdata/log' '/kdbdata/socket' '/kdbdata/tmp' '/kdbdata/mysql-files' '/kdbdata/certs')
for DIRECTORY in "${DIRS[@]}"
do
    if [ ! -d "$DIRECTORY" ]; then
        echo "Creating dir $DIRECTORY"
        mkdir "$DIRECTORY"
    fi
    echo "chown $DIRECTORY to mysql"
    chown mysql:mysql "$DIRECTORY"
done

# change /kdbdata owner
CUR_UNAME="$(stat -c '%U' /kdbdata)"
if [ "x${CUR_UNAME}" = "xmysql" ]; then
    echo "/kdbdata belongs to user $CUR_UNAME"
else
    echo "/kdbdata belongs to $CUR_UNAME , chown to mysql"
    chown mysql:mysql /kdbdata -R
fi

# check datadir and init
if [ -z "$(ls -A /kdbdata/data)" ]; then
    echo "/kdbdata/data is empty, initialize the dir"
    # init 
    mysqld --initialize-insecure --user=mysql --lower_case_table_names=1 --datadir=/kdbdata/data
else
    echo "/kdbdata/data is not empty, not initialize the dir"
fi

cp /etc/config/my.cnf /kdbdata/etc/
# start msyqld
# socket and port flags are required by agent
mysqld --user=mysql --socket=/kdbdata/socket/mysqld.sock --port=3306 --pid-file=/kdbdata/socket/mysqld.pid