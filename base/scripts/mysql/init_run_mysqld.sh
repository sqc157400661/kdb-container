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
    # init 
    mysqld --initialize-insecure --user=mysql --lower_case_table_names=1 --datadir=/kdbdata/data
    fresh_datadir=1
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

if [[ -n "${MYSQL_SERVER_ID}" && "${MYSQL_SERVER_ID}" =~ ^[1-9][0-9]*$ ]]; then
    MYSQLD_ARGS+=(--server_id="${MYSQL_SERVER_ID}")
fi

# ROLE is projected by the Operator from the certified topology plan. Apply
# standby fencing as a mysqld process argument so supervisor restarts cannot
# silently turn a replica writable when the base my.cnf is recopied.
ROLE_ARGS=()
case "${ROLE,,}" in
    replica|standby)
        ROLE_ARGS+=(--read-only=ON)
        ;;
esac

# The certified MySQL 8.0.37 image is shared by ordinary replication and MGR.
# Enable Group Replication only when the Operator supplies the complete MGR
# contract; ordinary topologies retain the existing startup path.
if [ "${ENABLE_MGR:-0}" = "1" ]; then
    if [ -z "${MGR_GROUP_NAME:-}" ] || [ -z "${MGR_LOCAL_ADDRESS:-}" ] || [ -z "${MGR_SEEDS:-}" ]; then
        echo "ENABLE_MGR=1 requires MGR_GROUP_NAME, MGR_LOCAL_ADDRESS and MGR_SEEDS" >&2
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

# The operator projects the generated root credential into the shared config
# volume. Initialise a fresh datadir with that credential before exposing the
# server; otherwise --initialize-insecure leaves root passwordless and the
# sidecar cannot establish its required SQL session. Existing datadirs are
# intentionally left untouched for migration safety; the fresh-datadir path
# applies the credential over the local socket before serving the sidecar.
root_password=""
if [ "${fresh_datadir}" = "1" ] && [ -r /etc/config/mysql-secret/root-password ]; then
    root_password="$(tr -d '\r\n' </etc/config/mysql-secret/root-password)"
fi

if [ -n "${root_password}" ]; then
    # Bootstrap over the local socket with networking disabled and before
    # standby fencing is enabled. super_read_only would otherwise reject the
    # one-time ALTER USER and leave a fresh replica passwordless.
    mysqld "${MYSQLD_ARGS[@]}" --skip-networking=ON &
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
    # mysql-community-client-core does not ship mysqladmin. Issue SHUTDOWN
    # through the installed mysql client and verify the child actually exits;
    # a client-side disconnect is acceptable only when the process is gone.
    mysql --protocol=socket --socket=/kdbdata/socket/mysqld.sock -uroot \
        -p"${root_password}" -e 'SHUTDOWN' >/dev/null 2>&1 || true
    for _ in $(seq 1 60); do
        if ! kill -0 "${mysqld_pid}" 2>/dev/null; then
            break
        fi
        sleep 1
    done
    if kill -0 "${mysqld_pid}" 2>/dev/null; then
        echo "failed to stop MySQL after credential bootstrap" >&2
        exit 1
    fi
    wait "${mysqld_pid}" || true
    trap - INT TERM EXIT
    rm -f "${credential_bootstrap_marker}"
elif [ "${fresh_datadir}" = "1" ]; then
    echo "fresh MySQL datadir requires /etc/config/mysql-secret/root-password" >&2
    exit 1
fi

exec mysqld "${MYSQLD_ARGS[@]}" "${ROLE_ARGS[@]}"
