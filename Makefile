ifndef CCPROOT
	export CCPROOT=./
endif

# Default values if not already set
IMAGE_PREFIX ?= kdbdeveloper
MySQL_IMAGE_TAG ?= v0.0.7
DOCKER_PLATFORM ?= linux/arm64
IMGCMDSTEM=docker build --platform $(DOCKER_PLATFORM)
REDIS_IMAGE_TAG ?= v0.0.2
MGR_MySQL_IMAGE_TAG ?= v0.0.1
PROXYSQL57_IMAGE_TAG ?= v0.0.1
PROXYSQL80_IMAGE_TAG ?= v0.0.1
PROXYSQL57_VERSION ?= 3.0.1
PROXYSQL80_VERSION ?= 3.0.2
MYSQLD_EXPORTER_IMAGE_TAG ?= v0.0.1
MYSQLD_EXPORTER_VERSION ?= 0.17.2
POSTGRESQL_IMAGE_TAG ?= v0.0.1
POSTGRESQL_MAJOR ?= 14
PATRONI_VERSION ?= 3.3.5
PG_BACKREST_VERSION ?= 2.48
CLICKHOUSE_IMAGE_TAG ?= 24.3-kdb.1
CLICKHOUSE_VERSION ?= 24.3
CLICKHOUSE_SIDECAR_IMAGE_TAG ?= v0.0.1
CLICKHOUSE_SIDECAR_GOARCH ?= $(if $(findstring amd64,$(DOCKER_PLATFORM)),amd64,arm64)
CLICKHOUSE_BACKUP_IMAGE_TAG ?= v0.0.1
CLICKHOUSE_BACKUP_VERSION ?= 2.6.23
KDB_SIDECAR_CONTEXT ?= ../kdb-sidecar
LOKI_IMAGE_TAG ?= 3.7.0-kdb.1
FLUENT_BIT_IMAGE_TAG ?= 5.0.6-kdb.1

mysql-base:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)base/Dockerfile.mysql \
		-t $(IMAGE_PREFIX)/mysql:v1.0.0 \
		$(CCPROOT)

mysql80:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/80/Dockerfile \
		-t $(IMAGE_PREFIX)/mysql80:$(MySQL_IMAGE_TAG) \
		$(CCPROOT)

mysql-base-amd64:
	docker buildx build --platform linux/amd64 --load \
		-f $(CCPROOT)base/Dockerfile.mysql \
		-t $(IMAGE_PREFIX)/mysql:v1.0.0 \
		$(CCPROOT)

mysql80-amd64: mysql-base-amd64
	docker buildx build --platform linux/amd64 --load \
		-f $(CCPROOT)/mysql/docker/80/Dockerfile \
		-t $(IMAGE_PREFIX)/mysql80:$(MySQL_IMAGE_TAG) \
		$(CCPROOT)


mysql57:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/57/Dockerfile \
		-t $(IMAGE_PREFIX)/mysql57:$(MySQL_IMAGE_TAG) \
		$(CCPROOT)

# MGR image build: make mysql80-mgr
mysql80-mgr:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/mgr/Dockerfile \
		-t $(IMAGE_PREFIX)/mysql80-mgr:$(MGR_MySQL_IMAGE_TAG) \
		$(CCPROOT)

# ProxySQL images build:
# make proxysql57
# make proxysql80
proxysql57:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/proxysql/Dockerfile \
		--build-arg PROXYSQL_VERSION=$(PROXYSQL57_VERSION) \
		-t $(IMAGE_PREFIX)/proxysql57:$(PROXYSQL57_IMAGE_TAG) \
		$(CCPROOT)

proxysql80:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/proxysql/Dockerfile \
		--build-arg PROXYSQL_VERSION=$(PROXYSQL80_VERSION) \
		-t $(IMAGE_PREFIX)/proxysql80:$(PROXYSQL80_IMAGE_TAG) \
		$(CCPROOT)

# MySQL exporter image build:
# make mysql-exporter
mysql-exporter:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/exporter/Dockerfile \
		--build-arg MYSQLD_EXPORTER_VERSION=$(MYSQLD_EXPORTER_VERSION) \
		-t $(IMAGE_PREFIX)/mysql-exporter:$(MYSQLD_EXPORTER_IMAGE_TAG) \
		$(CCPROOT)

# PostgreSQL image build:
# make postgresql14
postgresql14:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/postgresql/docker/14/Dockerfile \
		--build-arg POSTGRES_MAJOR=$(POSTGRESQL_MAJOR) \
		--build-arg PATRONI_VERSION=$(PATRONI_VERSION) \
		--build-arg PG_BACKREST_VERSION=$(PG_BACKREST_VERSION) \
		-t $(IMAGE_PREFIX)/postgresql14:$(POSTGRESQL_IMAGE_TAG) \
		$(CCPROOT)

# ClickHouse images build:
# make clickhouse-images
# make clickhouse
# make clickhouse-keeper
# make clickhouse-sidecar
# make clickhouse-backup
.PHONY: clickhouse-images clickhouse clickhouse-keeper clickhouse-sidecar clickhouse-backup
clickhouse-images: clickhouse clickhouse-keeper clickhouse-sidecar clickhouse-backup

clickhouse:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/clickhouse/docker/server/Dockerfile \
		--build-arg CLICKHOUSE_IMAGE=clickhouse/clickhouse-server:$(CLICKHOUSE_VERSION) \
		-t $(IMAGE_PREFIX)/clickhouse:$(CLICKHOUSE_IMAGE_TAG) \
		$(CCPROOT)

clickhouse-keeper:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/clickhouse/docker/keeper/Dockerfile \
		--build-arg CLICKHOUSE_IMAGE=clickhouse/clickhouse-server:$(CLICKHOUSE_VERSION) \
		-t $(IMAGE_PREFIX)/clickhouse-keeper:$(CLICKHOUSE_IMAGE_TAG) \
		$(CCPROOT)

clickhouse-sidecar:
	$(MAKE) -C $(KDB_SIDECAR_CONTEXT) clickhouse-sidecar-with-container-build \
		CLICKHOUSE_SIDECAR_IMAGE_NAME=$(IMAGE_PREFIX)/clickhouse-sidecar:$(CLICKHOUSE_SIDECAR_IMAGE_TAG) \
		GO_DOCKER_PLATFORM=$(DOCKER_PLATFORM) \
		GO_BUILD_ARCH=$(CLICKHOUSE_SIDECAR_GOARCH)

clickhouse-backup:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/clickhouse/docker/backup-runner/Dockerfile \
		--build-arg CLICKHOUSE_BACKUP_IMAGE=altinity/clickhouse-backup:$(CLICKHOUSE_BACKUP_VERSION) \
		-t $(IMAGE_PREFIX)/clickhouse-backup:$(CLICKHOUSE_BACKUP_IMAGE_TAG) \
		$(CCPROOT)

# Log collection images build:
# make logging-images
# make loki
# make fluent-bit
.PHONY: logging-images loki fluent-bit
logging-images: loki fluent-bit

loki:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/logging/loki/Dockerfile \
		-t $(IMAGE_PREFIX)/loki:$(LOKI_IMAGE_TAG) \
		$(CCPROOT)/logging/loki

fluent-bit:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/logging/fluent-bit/Dockerfile \
		-t $(IMAGE_PREFIX)/fluent-bit:$(FLUENT_BIT_IMAGE_TAG) \
		$(CCPROOT)/logging/fluent-bit

rd:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/redis/Dockerfile \
		-t $(IMAGE_PREFIX)/redis:$(REDIS_IMAGE_TAG) \
		$(CCPROOT)


ZIP_NAME ?= "kdb-container"-$(shell date +%Y%m%d%H%M).zip
.PHONY: zip
zip:
	zip -r "$(ZIP_NAME)" . -x "$(ZIP_NAME)"
	@printf "已生成压缩包: %s\n" "$(ZIP_NAME)"
