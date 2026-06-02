#!/bin/sh
set -eu

CONFIG_FILE="${MYSQLD_EXPORTER_CONFIG:-/etc/mysqld_exporter/.my.cnf}"
WEB_LISTEN_ADDRESS="${WEB_LISTEN_ADDRESS:-:9104}"

if [ ! -s "$CONFIG_FILE" ]; then
  MYSQL_EXPORTER_USER="${MYSQL_EXPORTER_USER:-exporter}"
  MYSQL_EXPORTER_PASSWORD="${MYSQL_EXPORTER_PASSWORD:-}"
  MYSQL_EXPORTER_HOST="${MYSQL_EXPORTER_HOST:-127.0.0.1}"
  MYSQL_EXPORTER_PORT="${MYSQL_EXPORTER_PORT:-3306}"
  MYSQL_EXPORTER_SOCKET="${MYSQL_EXPORTER_SOCKET:-}"

  umask 077
  {
    echo "[client]"
    echo "user=${MYSQL_EXPORTER_USER}"
    echo "password=${MYSQL_EXPORTER_PASSWORD}"
    if [ -n "$MYSQL_EXPORTER_SOCKET" ]; then
      echo "socket=${MYSQL_EXPORTER_SOCKET}"
    else
      echo "host=${MYSQL_EXPORTER_HOST}"
      echo "port=${MYSQL_EXPORTER_PORT}"
    fi
  } > "$CONFIG_FILE"
fi

EXTRA_ARGS="${MYSQLD_EXPORTER_EXTRA_ARGS:-}"

# Intentionally allow EXTRA_ARGS word splitting for collector flags such as:
# --collect.info_schema.innodb_metrics --collect.perf_schema.eventsstatements
# shellcheck disable=SC2086
exec /usr/local/bin/mysqld_exporter \
  --config.my-cnf="$CONFIG_FILE" \
  --web.listen-address="$WEB_LISTEN_ADDRESS" \
  $EXTRA_ARGS \
  "$@"
