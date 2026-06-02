FROM kdbdeveloper/mysql:v1.0.0

# Runtime env for MGR:
# ENABLE_MGR=1
# MGR_SERVER_ID=<unique-int>
# MGR_GROUP_NAME=<uuid>
# MGR_LOCAL_ADDRESS=<ip:33061>
# MGR_SEEDS=<ip1:33061,ip2:33061,...>
# Optional: MGR_START_ON_BOOT=OFF|ON, MGR_BOOTSTRAP_GROUP=OFF|ON, MGR_IP_ALLOWLIST=<cidr-list>

ENV MYSQL_MAJOR=8.0
ENV MYSQL_MAJOR_DIR=80
ENV MYSQL_VERSION=8.0.37-1debian11

COPY mysql/deb/"$MYSQL_MAJOR_DIR"/mysql-community-server-core_"$MYSQL_VERSION"_amd64.deb  /tmp/mysql-server.deb
COPY mysql/deb/"$MYSQL_MAJOR_DIR"/mysql-community-client-plugins_"$MYSQL_VERSION"_amd64.deb  /tmp/mysql-client-plugins.deb
COPY mysql/deb/"$MYSQL_MAJOR_DIR"/mysql-community-client-core_"$MYSQL_VERSION"_amd64.deb  /tmp/mysql-client-core.deb

RUN apt-get update

RUN apt-get -f install /tmp/mysql-server.deb -y && \
    apt-get -f install /tmp/mysql-client-plugins.deb -y && \
    apt-get -f install /tmp/mysql-client-core.deb -y && \
    rm /tmp/mysql-*.deb

COPY mysql/deb/"$MYSQL_MAJOR_DIR"/server_audit.so  /usr/lib/mysql/plugin/server_audit.so

# copy config
COPY mysql/scripts/mysqld_health.sh /kdb/bin/mysqld_health.sh
COPY mysql/scripts/mysqld_mgr.cnf /kdb/conf/mysqld.cnf
COPY mysql/scripts/init_run_mysqld_mgr.sh /kdb/bin/init_run_mysqld_mgr.sh
COPY mysql/scripts/supervisor_mysql_mgr.conf /etc/supervisor/conf.d/supervisor_mysql.conf

RUN chmod +x /kdb/bin/*
