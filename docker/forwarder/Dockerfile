FROM eclipse-temurin:21-jre-noble

ARG LABEL_MAINTAINER="Graylog, Inc. <hello@graylog.com>"
ARG LABEL_NAME="Graylog Forwarder Docker Image"
ARG LABEL_DESCRIPTION="Official Graylog Forwarder Docker image"
ARG LABEL_URL="https://www.graylog.org/"
ARG LABEL_VCS_URL="https://github.com/Graylog2/graylog-docker"
ARG LABEL_VENDOR="Graylog, Inc."
ARG SLUG="graylog"

ARG VCS_REF
ARG BUILD_DATE
ARG GRAYLOG_FORWARDER_VERSION
ARG GRAYLOG_FORWARDER_IMAGE_VERSION
ARG GRAYLOG_FORWARDER_ROOT=/usr/share/${SLUG}-forwarder
ARG GRAYLOG_FORWARDER_FILE=/tmp/${SLUG}-forwarder-bin.tar.gz
ARG DEBIAN_FRONTEND=noninteractive

# We default to an empty file instead of leaving LOCAL_BUILD_TGZ blank
# because Docker would execute the following COPY command with a blank
# value:
#   COPY "" "/tmp/forwarder.tgz"
# That creates a /tmp/forwarder.tgz *directory* in the container with
# all files from the build context.
ARG LOCAL_BUILD_TGZ=.empty

ENV FORWARDER_CONFIG_FILE=/etc/${SLUG}/forwarder/forwarder.conf
ENV FORWARDER_JVM_OPTIONS_FILE=/etc/${SLUG}/forwarder/jvm.options
ENV FORWARDER_DATA_DIR=/var/lib/${SLUG}-forwarder

# We are using an empty forwarder.conf file so we are setting defaults
# via environment variables:
ENV GRAYLOG_BIN_DIR=/usr/share/${SLUG}-forwarder/bin
ENV GRAYLOG_BIN_SCRIPT=${GRAYLOG_BIN_DIR}/${SLUG}-forwarder
ENV GRAYLOG_PLUGIN_DIR=/usr/share/${SLUG}-forwarder/plugin
ENV GRAYLOG_DATA_DIR=/var/lib/${SLUG}-forwarder/data
ENV GRAYLOG_MESSAGE_JOURNAL_DIR=/var/lib/${SLUG}-forwarder/journal
ENV GRAYLOG_NODE_ID_FILE=/var/lib/${SLUG}-forwarder/node-id

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -y install --no-install-recommends apt-utils && \
    apt-get -y install --no-install-recommends ca-certificates curl tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY "${LOCAL_BUILD_TGZ}" "/tmp/local-forwarder.tgz"

# An empty /tmp/forwarder.tgz file indicates that we don't use a
# custom LOCAL_BUILD_TGZ file.
RUN if [ -f "/tmp/local-forwarder.tgz" ] && [ -s "/tmp/local-forwarder.tgz" ]; then \
        mv "/tmp/local-forwarder.tgz" "$GRAYLOG_FORWARDER_FILE"; \
    fi

RUN if [ "${LOCAL_BUILD_TGZ}" = ".empty" ]; then \
      curl -fsSL --retry 3 --output "$GRAYLOG_FORWARDER_FILE" \
        "https://downloads.graylog.org/releases/cloud/forwarder/${GRAYLOG_FORWARDER_VERSION}/graylog-forwarder-${GRAYLOG_FORWARDER_VERSION}-bin.tar.gz"; \
    fi

RUN install -d -o root -g root -m 0755 "$GRAYLOG_FORWARDER_ROOT" && \
    tar -C "$GRAYLOG_FORWARDER_ROOT" -xzf "$GRAYLOG_FORWARDER_FILE" && \
    chown -R root.root "$GRAYLOG_FORWARDER_ROOT" && \
    install -d -o root -g root -m 0755 "$FORWARDER_DATA_DIR" && \
    install -d -o root -g root -m 0755 "$(dirname $FORWARDER_CONFIG_FILE)" && \
    touch "$FORWARDER_CONFIG_FILE" && \
    echo "forwarder_server_hostname =" >> "$FORWARDER_CONFIG_FILE" && \
    echo "forwarder_grpc_api_token =" >> "$FORWARDER_CONFIG_FILE" && \
    mv "${GRAYLOG_FORWARDER_ROOT}/config/jvm.options" "$FORWARDER_JVM_OPTIONS_FILE" && \
    rmdir "${GRAYLOG_FORWARDER_ROOT}/config" && \
    rm -f "$GRAYLOG_FORWARDER_FILE" "/tmp/local-forwarder.tgz"

COPY docker/forwarder/forwarder-entrypoint.sh /

LABEL maintainer="${LABEL_MAINTAINER}" \
      org.label-schema.name="${LABEL_NAME}" \
      org.label-schema.description="${LABEL_DESCRIPTION}" \
      org.label-schema.url="${LABEL_URL}" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="${LABEL_VCS_URL}" \
      org.label-schema.vendor="${LABEL_VENDOR}" \
      org.label-schema.version=${GRAYLOG_FORWARDER_IMAGE_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE}

ENTRYPOINT ["tini", "--", "/forwarder-entrypoint.sh"]
