FROM debian:bookworm-slim

ARG PROXYSQL_VERSION=3.0.2

RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates apt-transport-https && \
    wget -nv -O /usr/share/keyrings/proxysql-3.0.x-keyring.gpg "https://repo.proxysql.com/ProxySQL/proxysql-3.0.x/repo_pub_key.gpg" && \
    echo "deb [signed-by=/usr/share/keyrings/proxysql-3.0.x-keyring.gpg] https://repo.proxysql.com/ProxySQL/proxysql-3.0.x/bookworm/ ./" > /etc/apt/sources.list.d/proxysql.list && \
    apt-get update && \
    apt-get install -y proxysql=${PROXYSQL_VERSION}* && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 6032 6033

CMD ["proxysql", "-f", "-c", "/etc/proxysql.cnf"]
