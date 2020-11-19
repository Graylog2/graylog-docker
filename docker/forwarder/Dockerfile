FROM openjdk:8-jre-slim-buster

ARG VCS_REF
ARG BUILD_DATE
ARG GRAYLOG_FORWARDER_VERSION
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install --no-install-recommends apt-utils && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends ca-certificates curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN export GRAYLOG_FORWARDER_VERSION_SHORT=$(echo $GRAYLOG_FORWARDER_VERSION | cut -d. -f1).$(echo $GRAYLOG_FORWARDER_VERSION | cut -d. -f2) && \
    curl \
    --silent \
    --location \
    --retry 3 \
    --output "/tmp/graylog-$GRAYLOG_FORWARDER_VERSION_SHORT-repository_latest.deb" \
    "https://packages.graylog2.org/repo/packages/graylog-$GRAYLOG_FORWARDER_VERSION_SHORT-repository_latest.deb" && \
    dpkg -i /tmp/graylog-$GRAYLOG_FORWARDER_VERSION_SHORT-repository_latest.deb && \
    apt-get update && \
    apt-get -y install graylog-forwarder && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm /tmp/graylog-$GRAYLOG_FORWARDER_VERSION_SHORT-repository_latest.deb

LABEL maintainer="Graylog, Inc. <hello@graylog.com>" \
      org.label-schema.name="Graylog Forwarder Docker Image" \
      org.label-schema.description="Official Graylog Forwarder Docker image" \
      org.label-schema.url="https://www.graylog.org/" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="https://github.com/Graylog2/graylog-docker" \
      org.label-schema.vendor="Graylog, Inc." \
      org.label-schema.version=${GRAYLOG_FORWARDER_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE} \
      com.microscaling.docker.dockerfile="/Dockerfile"
