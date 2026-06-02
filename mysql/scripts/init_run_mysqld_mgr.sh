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
    mysqld --initialize-insecure --user=mysql --lower_case_table_names=1 --datadir=/kdbdata/data
else
    echo "/kdbdata/data is not empty, not initialize the dir"
fi

if [ -f /etc/config/my.cnf ]; then
    cp /etc/config/my.cnf /kdbdata/etc/
else
    cp /kdb/conf/mysqld.cnf /kdbdata/etc/my.cnf
fi

MYSQL_PORT="${MYSQL_PORT:-3306}"

MYSQLD_ARGS=(
    --user=mysql
    --socket=/kdbdata/socket/mysqld.sock
    "--port=${MYSQL_PORT}"
    --pid-file=/kdbdata/socket/mysqld.pid
)

SERVER_ID="${MYSQL_SERVER_ID:-${MGR_SERVER_ID:-}}"
if [ -n "${SERVER_ID}" ]; then
    MYSQLD_ARGS+=(--server_id="${SERVER_ID}")
fi

if [ "${ENABLE_MGR:-0}" = "1" ]; then
    if [ -z "${MGR_GROUP_NAME:-}" ] || [ -z "${MGR_LOCAL_ADDRESS:-}" ] || [ -z "${MGR_SEEDS:-}" ]; then
        echo "ENABLE_MGR=1 requires MGR_GROUP_NAME, MGR_LOCAL_ADDRESS and MGR_SEEDS"
        exit 1
    fi

    MYSQLD_ARGS+=(--plugin_load_add=group_replication.so)
    MYSQLD_ARGS+=(--loose-group_replication_group_name="${MGR_GROUP_NAME}")
    MYSQLD_ARGS+=(--loose-group_replication_local_address="${MGR_LOCAL_ADDRESS}")
    MYSQLD_ARGS+=(--loose-group_replication_group_seeds="${MGR_SEEDS}")
    MYSQLD_ARGS+=(--loose-group_replication_start_on_boot="${MGR_START_ON_BOOT:-OFF}")
    MYSQLD_ARGS+=(--loose-group_replication_bootstrap_group="${MGR_BOOTSTRAP_GROUP:-OFF}")
    MYSQLD_ARGS+=(--report-host="${MGR_LOCAL_ADDRESS%:*}")
    MYSQLD_ARGS+=("--report-port=${MYSQL_PORT}")

    if [ -n "${MGR_IP_ALLOWLIST:-}" ]; then
        MYSQLD_ARGS+=(--loose-group_replication_ip_allowlist="${MGR_IP_ALLOWLIST}")
    fi
fi

exec mysqld "${MYSQLD_ARGS[@]}"
