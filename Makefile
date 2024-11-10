ifndef CCPROOT
	export CCPROOT=./
endif

# Default values if not already set
IMAGE_PREFIX ?= kdb
MySQL_IMAGE_TAG ?= v0.0.1
IMGCMDSTEM=docker build


mysql-base:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/base/Dockerfile.mysql \
		-t $(IMAGE_PREFIX)/kdb_mysql_base:v1.0.0 \
		$(CCPROOT)

mysql80:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/80/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/mysql80:$(MySQL_IMAGE_TAG) \
		$(CCPROOT)


mysql80:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/mysql/docker/57/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/mysql57:$(MySQL_IMAGE_TAG) \
		$(CCPROOT)

