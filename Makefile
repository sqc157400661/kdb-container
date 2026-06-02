ifndef CCPROOT
	export CCPROOT=./
endif

# Default values if not already set
IMAGE_PREFIX ?= kdbdeveloper
MySQL_IMAGE_TAG ?= v0.0.7
IMGCMDSTEM=docker build --platform linux/arm64
REDIS_IMAGE_TAG ?= v0.0.2
MGR_MySQL_IMAGE_TAG ?= v0.0.1
PROXYSQL57_IMAGE_TAG ?= v0.0.1
PROXYSQL80_IMAGE_TAG ?= v0.0.1
PROXYSQL57_VERSION ?= 3.0.1
PROXYSQL80_VERSION ?= 3.0.2
MYSQLD_EXPORTER_IMAGE_TAG ?= v0.0.1
MYSQLD_EXPORTER_VERSION ?= 0.17.2

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