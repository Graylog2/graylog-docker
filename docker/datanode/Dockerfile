FROM ubuntu:22.04

# Build time variables - not persistent in the container image
ARG BUILD_DATE
ARG BUILD_VERSION
ARG SNAPSHOT_URL_X64
ARG SNAPSHOT_URL_AARCH64
ARG LOCAL_ARTIFACT
ARG DEBIAN_FRONTEND=noninteractive

# Will be persistet in the container image
ENV GDN_APP_ROOT=/usr/share/graylog-datanode
ENV GDN_DATA_ROOT=/var/lib/graylog-datanode
ENV GDN_CONFIG_DIR=/etc/graylog/datanode
ENV GDN_CONFIG_FILE=$GDN_CONFIG_DIR/datanode.conf
ENV GDN_FEATURE_FLAG_FILE=$GDN_CONFIG_DIR/feature-flag.conf
ENV GDN_JVM_OPTIONS_FILE=$GDN_CONFIG_DIR/jvm.options
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

# Setting LOCAL_ARTIFACT to a filename in the build context and setting
# SNAPSHOT_URL to "file:///tmp/graylog-datanode.tgz" allows the build with
# a local artifact build.
# The COPY operation is does nothing if LOCAL_ARTIFACT is not set.
COPY "$LOCAL_ARTIFACT" /tmp/graylog-datanode.tgz

RUN install -d -o root -g root -m 0755 "$GDN_APP_ROOT" \
    && if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
         export SNAPSHOT_URL="$SNAPSHOT_URL_AARCH64"; \
       else \
         export SNAPSHOT_URL="$SNAPSHOT_URL_X64"; \
       fi \
    && curl -fsSL --retry 3 "$SNAPSHOT_URL" | \
       tar -C "$GDN_APP_ROOT" --strip-components=1 -xzf - \
    && rm -rf "/tmp/graylog-datanode.tgz" \
    && mv "$GDN_APP_ROOT/config/"* "$GDN_CONFIG_DIR"/ \
    && rmdir "$GDN_APP_ROOT/config" \
    && chown -R "$GDN_USER":"$GDN_GROUP" "$GDN_CONFIG_DIR" \
    && chown -R root:root "$GDN_APP_ROOT"

RUN apt-get purge -y curl \
    && apt-get autoremove -y --purge \
    && rm -rf /var/log/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["graylog-datanode"]

# Put at the very end to avoid rebuilding all layers for ARG changes like
# BUILD_DATE, BUILD_REV, and BUILD_VERSION.
LABEL org.opencontainers.image.authors="Graylog, Inc. <hello@graylog.com>"
LABEL org.opencontainers.image.created="$BUILD_DATE"
LABEL org.opencontainers.image.description="Container image to run the Graylog Data Node"
LABEL org.opencontainers.image.documentation="https://docs.graylog.org/"
LABEL org.opencontainers.image.licenses="SSPL-1.0"
LABEL org.opencontainers.image.source="https://github.com/Graylog2/graylog2-server"
LABEL org.opencontainers.image.title="Graylog Data Node"
LABEL org.opencontainers.image.url="https://www.graylog.org/"
LABEL org.opencontainers.image.vendor="Graylog, Inc."
LABEL org.opencontainers.image.version="$BUILD_VERSION"
