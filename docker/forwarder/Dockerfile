FROM openjdk:8-jre-slim-buster

ARG VCS_REF
ARG BUILD_DATE
ARG GRAYLOG_FORWARDER_PACKAGE_VERSION
ARG DEBIAN_FRONTEND=noninteractive
ENV FORWARDER_JVM_OPTIONS_FILE=/etc/graylog/forwarder/jvm.options

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -y install --no-install-recommends apt-utils && \
    apt-get -y install --no-install-recommends ca-certificates curl tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN GRAYLOG_FORWARDER_VERSION_MAJOR=$(echo $GRAYLOG_FORWARDER_PACKAGE_VERSION | cut -d. -f1) && \
    export GRAYLOG_FORWARDER_VERSION_MAJOR && \
    curl \
    --silent \
    --location \
    --retry 3 \
    --output "/tmp/graylog-forwarder_${GRAYLOG_FORWARDER_PACKAGE_VERSION}_all.deb" \
    "https://packages.graylog2.org/repo/debian/pool/forwarder-stable/${GRAYLOG_FORWARDER_VERSION_MAJOR}/g/graylog-forwarder/graylog-forwarder_${GRAYLOG_FORWARDER_PACKAGE_VERSION}_all.deb" && \
    dpkg -i /tmp/graylog-forwarder_${GRAYLOG_FORWARDER_PACKAGE_VERSION}_all.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm /tmp/graylog-forwarder_${GRAYLOG_FORWARDER_PACKAGE_VERSION}_all.deb

COPY docker/forwarder/forwarder-entrypoint.sh /

LABEL maintainer="Graylog, Inc. <hello@graylog.com>" \
      org.label-schema.name="Graylog Forwarder Docker Image" \
      org.label-schema.description="Official Graylog Forwarder Docker image" \
      org.label-schema.url="https://www.graylog.org/" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="https://github.com/Graylog2/graylog-docker" \
      org.label-schema.vendor="Graylog, Inc." \
      org.label-schema.version=${GRAYLOG_FORWARDER_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE}

ENTRYPOINT ["tini", "--", "/forwarder-entrypoint.sh"]
