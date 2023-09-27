FROM ubuntu:22.04

# Build time variables - not persistent in the container image
ARG GRAYLOG_VERSION
ARG VCS_REF
ARG BUILD_DATE
# The LOCAL_BUILD_TGZ variable defaults to an empty file. If the variable is
# empty, Docker copies the full context dir into the container. It basically
# executes the following:
#   COPY "" "/tmp/datanode-local.tar.gz"
# That creates a /tmp/datanode-local.tar.gz in the container with all files
# from the build context.
ARG LOCAL_BUILD_TGZ=.empty
ARG SNAPSHOT_URL_X64=https://downloads.graylog.org/releases/graylog-datanode/graylog-datanode-${GRAYLOG_VERSION}-linux-x64.tgz
ARG SNAPSHOT_URL_AARCH64=https://downloads.graylog.org/releases/graylog-datanode/graylog-datanode-${GRAYLOG_VERSION}-linux-aarch64.tgz
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETPLATFORM

# Will be persistet in the container image
ENV GDN_APP_ROOT=/usr/share/graylog-datanode
ENV GDN_DATA_ROOT=/var/lib/graylog-datanode
ENV GDN_CONFIG_DIR=/etc/graylog/datanode
ENV GDN_CONFIG_FILE=$GDN_CONFIG_DIR/datanode.conf
ENV GDN_FEATURE_FLAG_FILE=$GDN_CONFIG_DIR/feature-flag.conf
ENV GDN_JVM_OPTIONS_FILE=$GDN_CONFIG_DIR/jvm.options
ENV GDN_LOG4J_CONFIG_FILE=$GDN_CONFIG_DIR/log4j2.xml
ENV GDN_GROUP=graylog
ENV GDN_USER=graylog

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN groupadd -r "$GDN_GROUP" \
    && useradd --no-log-init -r \
      -s "/usr/sbin/nologin" \
      -d "$GDN_DATA_ROOT" \
      -g "$GDN_GROUP" \
      "$GDN_USER" \
    && install -d -o "$GDN_USER" -g "$GDN_GROUP" -m 0700 "$GDN_DATA_ROOT" \
    && install -d -o "$GDN_USER" -g "$GDN_GROUP" -m 0700 "$GDN_CONFIG_DIR" \
    && touch "$GDN_CONFIG_FILE" \
    && chown "$GDN_USER":"$GDN_GROUP" "$GDN_CONFIG_FILE"

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tini \
    && apt-get clean \
    && rm -rf \
      /tmp/* \
      /usr/share/doc/* \
      /usr/share/X11 \
      /var/cache/debconf/* \
      /var/lib/apt/lists/* \
      /var/log/*

RUN install -d -o root -g root -m 0755 "$GDN_APP_ROOT"

COPY "${LOCAL_BUILD_TGZ}" "/tmp/datanode-local.tar.gz"

# An empty /tmp/datanode-local.tar.gz file indicates that we don't use a
# custom LOCAL_BUILD_TGZ file.
RUN if [ -f /tmp/datanode-local.tar.gz ] && [ -s /tmp/datanode-local.tar.gz ]; then \
      mv /tmp/datanode-local.tar.gz /tmp/datanode.tar.gz; \
    fi; \
    if [ "${LOCAL_BUILD_TGZ}" == ".empty" ]; then \
      if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
         export SNAPSHOT_URL="$SNAPSHOT_URL_AARCH64"; \
       else \
         export SNAPSHOT_URL="$SNAPSHOT_URL_X64"; \
      fi; \
      curl -fsSL --retry 3 "$SNAPSHOT_URL" -o /tmp/datanode.tar.gz; \
    fi; \
    tar -C "$GDN_APP_ROOT" --strip-components=1 -xzf /tmp/datanode.tar.gz \
    && rm -rf /tmp/datanode-local.tar.gz /tmp/datanode.tar.gz \
    && mv "$GDN_APP_ROOT/config/"* "$GDN_CONFIG_DIR"/ \
    && rmdir "$GDN_APP_ROOT/config" \
    && chown -R "$GDN_USER":"$GDN_GROUP" "$GDN_CONFIG_DIR" \
    && chown -R root:root "$GDN_APP_ROOT"

RUN apt-get purge -y curl \
    && apt-get autoremove -y --purge \
    && rm -rf /var/log/*

COPY docker/datanode/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["graylog-datanode"]

# Put at the very end to avoid rebuilding all layers for ARG changes like
# BUILD_DATE, VCS_REV, and GRAYLOG_VERSION.
LABEL org.opencontainers.image.authors="Graylog, Inc. <hello@graylog.com>"
LABEL org.opencontainers.image.created="$BUILD_DATE"
LABEL org.opencontainers.image.description="Container image to run the Graylog Data Node"
LABEL org.opencontainers.image.documentation="https://docs.graylog.org/"
LABEL org.opencontainers.image.licenses="SSPL-1.0"
LABEL org.opencontainers.image.revision="$VCS_REF"
LABEL org.opencontainers.image.source="https://github.com/Graylog2/graylog-docker"
LABEL org.opencontainers.image.title="Graylog Data Node"
LABEL org.opencontainers.image.url="https://www.graylog.org/"
LABEL org.opencontainers.image.vendor="Graylog, Inc."
LABEL org.opencontainers.image.version="$GRAYLOG_VERSION"
