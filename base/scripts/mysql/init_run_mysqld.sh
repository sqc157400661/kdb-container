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

if [[ -n "${MYSQL_SERVER_ID}" && "${MYSQL_SERVER_ID}" =~ ^[1-9][0-9]*$ ]]; then
    echo "MYSQL_SERVER_ID is valid: ${MYSQL_SERVER_ID}, update server_id in /kdbdata/etc/my.cnf"
    sed -ri "s/^[[:space:]]*server_id[[:space:]]*=.*/server_id=${MYSQL_SERVER_ID}/g" /kdbdata/etc/my.cnf
    sed -ri "s/^[[:space:]]*server-id[[:space:]]*=.*/server-id=${MYSQL_SERVER_ID}/g" /kdbdata/etc/my.cnf
else
    echo "MYSQL_SERVER_ID is empty or invalid, skip server_id update"
fi

# start msyqld
# socket and port flags are required by agent
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQLD_ARGS=(
    --user=mysql
    --socket=/kdbdata/socket/mysqld.sock
    "--port=${MYSQL_PORT}"
    --pid-file=/kdbdata/socket/mysqld.pid
)

exec mysqld "${MYSQLD_ARGS[@]}"
