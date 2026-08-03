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
fresh_datadir=0
credential_bootstrap_marker=/kdbdata/.mysql-credential-bootstrap
if [ -z "$(ls -A /kdbdata/data)" ]; then
    echo "/kdbdata/data is empty, initialize the dir"
    touch "${credential_bootstrap_marker}"
    mysqld --initialize-insecure --user=mysql --lower_case_table_names=1 --datadir=/kdbdata/data
    fresh_datadir=1
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

# The Operator projects the authoritative initial role to every container.
# Apply standby fencing at mysqld process start so it survives supervisor
# restarts and is not lost when the projected base my.cnf is recopied.
case "${ROLE,,}" in
    replica|standby)
        MYSQLD_ARGS+=(--read-only=ON)
        ;;
esac

# Keep a fresh MySQL datadir's root credential aligned with the Secret
# projected by the operator. Existing datadirs are not rewritten implicitly;
# the fresh-datadir path applies the credential over the local socket.
root_password=""
if [ "${fresh_datadir}" = "1" ] && [ -r /etc/config/mysql-secret/root-password ]; then
    root_password="$(tr -d '\r\n' </etc/config/mysql-secret/root-password)"
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

if [ -n "${root_password}" ]; then
    mysqld "${MYSQLD_ARGS[@]}" &
    mysqld_pid=$!
    trap 'kill "${mysqld_pid}" 2>/dev/null || true' INT TERM EXIT
    for _ in $(seq 1 60); do
        if [ -S /kdbdata/socket/mysqld.sock ] && mysql --protocol=socket --socket=/kdbdata/socket/mysqld.sock -uroot -e 'SELECT 1' >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    escaped_password="$(printf '%s' "${root_password}" | sed "s/[\\']/\\\\&/g")"
    if ! mysql --protocol=socket --socket=/kdbdata/socket/mysqld.sock -uroot \
        -e "SET SESSION sql_log_bin=OFF; ALTER USER 'root'@'localhost' IDENTIFIED BY '${escaped_password}';"; then
        echo "failed to apply generated MySQL root credential" >&2
        exit 1
    fi
    rm -f "${credential_bootstrap_marker}"
    wait "${mysqld_pid}"
    exit $?
elif [ "${fresh_datadir}" = "1" ]; then
    echo "fresh MySQL datadir requires /etc/config/mysql-secret/root-password" >&2
    exit 1
fi

exec mysqld "${MYSQLD_ARGS[@]}"
