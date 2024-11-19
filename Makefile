ifndef CCPROOT
	export CCPROOT=./
endif

# Default values if not already set
IMAGE_PREFIX ?= kdbdeveloper
MySQL_IMAGE_TAG ?= v0.0.2
IMGCMDSTEM=docker build
REDIS_IMAGE_TAG ?= v0.0.1

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


# docker run -d --name redis -p 6379:6379 kdbdeveloper/redis:v0.0.1
redis:
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/redis/Dockerfile \
		-t $(IMAGE_PREFIX)/redis:$(REDIS_IMAGE_TAG) \
		$(CCPROOT)