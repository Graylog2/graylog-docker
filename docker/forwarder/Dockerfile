FROM openjdk:8-jre-slim-bullseye

ARG VCS_REF
ARG BUILD_DATE
ARG GRAYLOG_FORWARDER_VERSION
ARG GRAYLOG_FORWARDER_IMAGE_VERSION
ARG GRAYLOG_FORWARDER_ROOT=/usr/share/graylog-forwarder
ARG GRAYLOG_FORWARDER_FILE=/tmp/graylog-forwarder-bin.tar.gz
ARG DEBIAN_FRONTEND=noninteractive

ENV FORWARDER_CONFIG_FILE=/etc/graylog/forwarder/forwarder.conf
ENV FORWARDER_JVM_OPTIONS_FILE=/etc/graylog/forwarder/jvm.options
ENV FORWARDER_DATA_DIR=/var/lib/graylog-forwarder

# We are using an empty forwarder.conf file so we are setting defaults
# via environment variables:
ENV GRAYLOG_BIN_DIR=/usr/share/graylog-forwarder/bin
ENV GRAYLOG_PLUGIN_DIR=/usr/share/graylog-forwarder/plugin
ENV GRAYLOG_DATA_DIR=/var/lib/graylog-forwarder/data
ENV GRAYLOG_MESSAGE_JOURNAL_DIR=/var/lib/graylog-forwarder/journal

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -y install --no-install-recommends apt-utils && \
    apt-get -y install --no-install-recommends ca-certificates curl tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl \
    --silent \
    --location \
    --retry 3 \
    --output "$GRAYLOG_FORWARDER_FILE" \
    "https://downloads.graylog.org/releases/cloud/forwarder/${GRAYLOG_FORWARDER_VERSION}/graylog-forwarder-${GRAYLOG_FORWARDER_VERSION}-bin.tar.gz" && \
    install -d -o root -g root -m 0755 "$GRAYLOG_FORWARDER_ROOT" && \
    tar -C "$GRAYLOG_FORWARDER_ROOT" -xzf "$GRAYLOG_FORWARDER_FILE" && \
    chown -R root.root "$GRAYLOG_FORWARDER_ROOT" && \
    install -d -o root -g root -m 0755 "$FORWARDER_DATA_DIR" && \
    install -d -o root -g root -m 0755 "$(dirname $FORWARDER_CONFIG_FILE)" && \
    touch "$FORWARDER_CONFIG_FILE" && \
    echo "forwarder_server_hostname =" >> "$FORWARDER_CONFIG_FILE" && \
    echo "forwarder_grpc_api_token =" >> "$FORWARDER_CONFIG_FILE" && \
    mv "${GRAYLOG_FORWARDER_ROOT}/config/jvm.options" "$FORWARDER_JVM_OPTIONS_FILE" && \
    rmdir "${GRAYLOG_FORWARDER_ROOT}/config" && \
    rm -f "$GRAYLOG_FORWARDER_FILE"

COPY docker/forwarder/forwarder-entrypoint.sh /

LABEL maintainer="Graylog, Inc. <hello@graylog.com>" \
      org.label-schema.name="Graylog Forwarder Docker Image" \
      org.label-schema.description="Official Graylog Forwarder Docker image" \
      org.label-schema.url="https://www.graylog.org/" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="https://github.com/Graylog2/graylog-docker" \
      org.label-schema.vendor="Graylog, Inc." \
      org.label-schema.version=${GRAYLOG_FORWARDER_IMAGE_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE}

ENTRYPOINT ["tini", "--", "/forwarder-entrypoint.sh"]
