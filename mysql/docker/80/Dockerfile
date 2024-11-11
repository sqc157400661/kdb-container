FROM kdbdeveloper/mysql:v1.0.0

ENV MYSQL_MAJOR 8.0
ENV MYSQL_MAJOR_DIR 80
ENV MYSQL_VERSION 8.0.37-1debian11


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
COPY mysql/scripts/mysqld.cnf /kdb/conf/mysqld.cnf


RUN chmod +x /kdb/bin/mysqld_health.sh




