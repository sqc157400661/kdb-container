ifndef CCPROOT
	export CCPROOT=./
endif

# Default values if not already set
IMAGE_PREFIX ?= kdbdeveloper
UBI8_BASE_IMAGE_TAG ?= latest
MySQL_IMAGE_TAG ?= v0.0.7
HOST_GOARCH_RAW := $(shell go env GOARCH 2>/dev/null || uname -m)
HOST_GOARCH := $(if $(filter x86_64,$(HOST_GOARCH_RAW)),amd64,$(if $(filter aarch64,$(HOST_GOARCH_RAW)),arm64,$(HOST_GOARCH_RAW)))
TARGETOS ?= linux
TARGETARCH ?= $(HOST_GOARCH)
DOCKER_PLATFORM ?= $(TARGETOS)/$(TARGETARCH)
DOCKER_PLATFORM_PARTS := $(subst /, ,$(DOCKER_PLATFORM))
DOCKER_PLATFORM_ARCH := $(word 2,$(DOCKER_PLATFORM_PARTS))
IMGCMDSTEM=docker build --platform $(DOCKER_PLATFORM)
REDIS_IMAGE_TAG ?= v0.0.2
MGR_MySQL_IMAGE_TAG ?= v0.0.1
PROXYSQL57_IMAGE_TAG ?= v0.0.1
PROXYSQL80_IMAGE_TAG ?= v0.0.1
PROXYSQL57_VERSION ?= 3.0.1
PROXYSQL80_VERSION ?= 3.0.2
MYSQLD_EXPORTER_IMAGE ?= $(IMAGE_PREFIX)/mysql-exporter
MYSQLD_EXPORTER_IMAGE_TAG ?= v0.0.1
MYSQLD_EXPORTER_VERSION ?= 0.19.0
PROMETHEUS_OPERATOR_VERSION ?= v0.92.0
PROMETHEUS_OPERATOR_IMAGE ?= $(IMAGE_PREFIX)/prometheus-operator
PROMETHEUS_OPERATOR_IMAGE_TAG ?= $(PROMETHEUS_OPERATOR_VERSION)
PROMETHEUS_CONFIG_RELOADER_VERSION ?= v0.92.0
PROMETHEUS_CONFIG_RELOADER_IMAGE ?= $(IMAGE_PREFIX)/prometheus-config-reloader
PROMETHEUS_CONFIG_RELOADER_IMAGE_TAG ?= $(PROMETHEUS_CONFIG_RELOADER_VERSION)
PROMETHEUS_VERSION ?= v3.12.0
PROMETHEUS_IMAGE ?= $(IMAGE_PREFIX)/prometheus
PROMETHEUS_IMAGE_TAG ?= $(PROMETHEUS_VERSION)
ALERTMANAGER_VERSION ?= v0.33.0
ALERTMANAGER_IMAGE ?= $(IMAGE_PREFIX)/alertmanager
ALERTMANAGER_IMAGE_TAG ?= $(ALERTMANAGER_VERSION)
GRAFANA_VERSION ?= 12.0.1
GRAFANA_IMAGE ?= $(IMAGE_PREFIX)/grafana
GRAFANA_IMAGE_TAG ?= $(GRAFANA_VERSION)
POSTGRESQL_IMAGE_TAG ?= v0.0.1
POSTGRESQL_MAJOR ?= 14
PATRONI_VERSION ?= 3.3.5
PG_BACKREST_VERSION ?= 2.48
CLICKHOUSE_IMAGE_TAG ?= 24.3-kdb.1
CLICKHOUSE_VERSION ?= 24.3
CLICKHOUSE_SIDECAR_IMAGE_TAG ?= v0.0.1
CLICKHOUSE_SIDECAR_GOARCH ?= $(DOCKER_PLATFORM_ARCH)
CLICKHOUSE_BACKUP_IMAGE_TAG ?= v0.0.1
CLICKHOUSE_BACKUP_VERSION ?= 2.6.23
KDB_SIDECAR_CONTEXT ?= ../kdb-sidecar
LOKI_IMAGE_TAG ?= 3.7.0-kdb.1
FLUENT_BIT_IMAGE_TAG ?= 5.0.6-kdb.1

.PHONY: ubi8-base
ubi8-base:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/base/ubi8-base/Dockerfile \
		-t $(IMAGE_PREFIX)/ubi8-base:$(UBI8_BASE_IMAGE_TAG) \
		$(CCPROOT)/base/ubi8-base

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
.PHONY: mysql-exporter
mysql-exporter:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/exporter/Dockerfile \
		--build-arg MYSQLD_EXPORTER_VERSION=$(MYSQLD_EXPORTER_VERSION) \
		-t $(MYSQLD_EXPORTER_IMAGE):$(MYSQLD_EXPORTER_IMAGE_TAG) \
		$(CCPROOT)

# Monitoring images build:
# make monitoring-images
# make prometheus-operator
# make prometheus-config-reloader
# make prometheus
# make alertmanager
# make grafana
.PHONY: monitoring-images prometheus-operator prometheus-config-reloader prometheus alertmanager grafana
monitoring-images: prometheus-operator prometheus-config-reloader prometheus alertmanager grafana

prometheus-operator:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/monitoring/prometheus-operator/Dockerfile \
		--build-arg PROMETHEUS_OPERATOR_UPSTREAM_IMAGE=quay.io/prometheus-operator/prometheus-operator:$(PROMETHEUS_OPERATOR_VERSION) \
		-t $(PROMETHEUS_OPERATOR_IMAGE):$(PROMETHEUS_OPERATOR_IMAGE_TAG) \
		$(CCPROOT)/monitoring/prometheus-operator

prometheus-config-reloader:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/monitoring/prometheus-config-reloader/Dockerfile \
		--build-arg PROMETHEUS_CONFIG_RELOADER_UPSTREAM_IMAGE=quay.io/prometheus-operator/prometheus-config-reloader:$(PROMETHEUS_CONFIG_RELOADER_VERSION) \
		-t $(PROMETHEUS_CONFIG_RELOADER_IMAGE):$(PROMETHEUS_CONFIG_RELOADER_IMAGE_TAG) \
		$(CCPROOT)/monitoring/prometheus-config-reloader

prometheus:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/monitoring/prometheus/Dockerfile \
		--build-arg PROMETHEUS_UPSTREAM_IMAGE=quay.io/prometheus/prometheus:$(PROMETHEUS_VERSION) \
		-t $(PROMETHEUS_IMAGE):$(PROMETHEUS_IMAGE_TAG) \
		$(CCPROOT)/monitoring/prometheus

alertmanager:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/monitoring/alertmanager/Dockerfile \
		--build-arg ALERTMANAGER_UPSTREAM_IMAGE=quay.io/prometheus/alertmanager:$(ALERTMANAGER_VERSION) \
		-t $(ALERTMANAGER_IMAGE):$(ALERTMANAGER_IMAGE_TAG) \
		$(CCPROOT)/monitoring/alertmanager

grafana:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/monitoring/grafana/Dockerfile \
		--build-arg GRAFANA_UPSTREAM_IMAGE=grafana/grafana:$(GRAFANA_VERSION) \
		-t $(GRAFANA_IMAGE):$(GRAFANA_IMAGE_TAG) \
		$(CCPROOT)/monitoring/grafana

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
