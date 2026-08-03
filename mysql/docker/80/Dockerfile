ARG MYSQL_BASE_IMAGE=kdbdeveloper/mysql:v1.0.0
FROM ${MYSQL_BASE_IMAGE}

ARG MYSQL_INSTALL_DEBS=1

ENV MYSQL_MAJOR=8.0
ENV MYSQL_MAJOR_DIR=80
ENV MYSQL_VERSION=8.0.37-1debian11


COPY mysql/deb/"$MYSQL_MAJOR_DIR"/mysql-community-server-core_"$MYSQL_VERSION"_amd64.deb  /tmp/mysql-server.deb
COPY mysql/deb/"$MYSQL_MAJOR_DIR"/mysql-community-client-plugins_"$MYSQL_VERSION"_amd64.deb  /tmp/mysql-client-plugins.deb
COPY mysql/deb/"$MYSQL_MAJOR_DIR"/mysql-community-client-core_"$MYSQL_VERSION"_amd64.deb  /tmp/mysql-client-core.deb

RUN if [ "${MYSQL_INSTALL_DEBS}" = "1" ]; then \
      apt-get update && \
      apt-get -f install /tmp/mysql-server.deb -y && \
      apt-get -f install /tmp/mysql-client-plugins.deb -y && \
      apt-get -f install /tmp/mysql-client-core.deb -y; \
    fi; \
    rm -f /tmp/mysql-*.deb


COPY mysql/deb/"$MYSQL_MAJOR_DIR"/server_audit.so  /usr/lib/mysql/plugin/server_audit.so


# copy config
COPY mysql/scripts/mysqld_health.sh /kdb/bin/mysqld_health.sh
COPY mysql/scripts/mysqld.cnf /kdb/conf/mysqld.cnf

# Keep the versioned image self-contained. The base image is intentionally
# reused offline, but its entrypoint and supervisor contract must follow this
# source snapshot; otherwise a remote build would silently retain an older
# credential bootstrap implementation from the prebuilt base layer.
COPY base/scripts/mysql/init_run_mysqld.sh /kdb/bin/init_run_mysqld.sh
COPY base/scripts/mysql/supervisor_mysql.conf /etc/supervisor/conf.d/supervisor_mysql.conf


RUN chmod +x /kdb/bin/*


