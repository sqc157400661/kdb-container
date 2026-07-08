FROM registry.access.redhat.com/ubi8-minimal:latest

LABEL maintainers="kdbdeveloper"
LABEL description="Common UBI8 minimal base image for KDB containers"
LABEL org.opencontainers.image.title="kdbdeveloper/ubi8-base"
LABEL org.opencontainers.image.base.name="registry.access.redhat.com/ubi8-minimal:latest"

# Shared runtime/debugging tools used by existing UBI8-based KDB images.
# Version-sensitive database packages and build toolchains stay in downstream images.
RUN microdnf update -y --nodocs && \
    microdnf install -y --nodocs \
        bind-utils \
        ca-certificates \
        curl \
        gettext \
        glibc-langpack-en \
        hostname \
        iputils \
        less \
        nss_wrapper \
        procps-ng \
        tzdata \
        vim-minimal \
        wget \
        yum && \
    microdnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum

ENV LANG=en_US.utf-8
ENV LC_ALL=en_US.utf-8
