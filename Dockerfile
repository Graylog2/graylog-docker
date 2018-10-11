# First stage: obtain Graylog, verify the download and extract it.
# 'buildpack-deps:stretch-curl' image, because it's smaller, and a base layer
# in the 'openjdk:8-jre-stretch' image used in the later stage.
FROM buildpack-deps:stretch-curl as obtain-graylog-stage

RUN mkdir /usr/local/share/graylog
WORKDIR /tmp
ARG GRAYLOG_VERSION
RUN wget -nv -O "graylog-${GRAYLOG_VERSION}.tgz" \
  "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz"
# Hadolint suggests using pipefail, not available on /bin/sh.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -nv -O - \
  "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz.sha256.txt" \
    | sha256sum -c -
RUN tar -xzf "graylog-${GRAYLOG_VERSION}.tgz" \
  --strip-components=1 -C /usr/local/share/graylog
# chown in this stage, because 'COPY --chown' does not work with build
# arguments yet, and a later 'RUN chown' would result in another ~ 140MB layer.
# See also https://github.com/moby/moby/issues/35018.
ARG GRAYLOG_UID=1100
ARG GRAYLOG_GID=1100
RUN chown -R "${GRAYLOG_UID}:${GRAYLOG_GID}" /usr/local/share/graylog

# Final stage
FROM openjdk:8-jre-stretch

LABEL maintainer="Graylog, Inc. <hello@graylog.com>" \
      org.label-schema.name="Graylog Docker Image" \
      org.label-schema.description="Official Graylog Docker image" \
      org.label-schema.url="https://www.graylog.org/" \
      org.label-schema.vcs-url="https://github.com/Graylog2/graylog-docker" \
      org.label-schema.vendor="Graylog, Inc." \
      org.label-schema.schema-version="1.0" \
      com.microscaling.docker.dockerfile="/Dockerfile" \
      com.microscaling.license="Apache 2.0"

# hadolint ignore=DL3008
RUN set -x \
  && apt-get update && apt-get -y --no-install-recommends install \
    'gosu=1.10-*' \
    libcap2-bin \
  && rm -rf /var/lib/apt/lists/* \
  && setcap 'cap_net_bind_service=+ep' "${JAVA_HOME}/bin/java"

ARG GRAYLOG_USER=graylog
ARG GRAYLOG_UID=1100
ARG GRAYLOG_GROUP=graylog
ARG GRAYLOG_GID=1100
RUN addgroup --gid "${GRAYLOG_GID}" "${GRAYLOG_GROUP}" \
  && adduser --disabled-login --gecos 'Graylog,,,' --uid "${GRAYLOG_UID}" --gid "${GRAYLOG_GID}" "${GRAYLOG_USER}"

COPY --from=obtain-graylog-stage /usr/local/share/graylog /usr/share/graylog

ARG VCS_REF
ARG GRAYLOG_VERSION
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$GRAYLOG_VERSION

ENV GRAYLOG_SERVER_JAVA_OPTS "-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:NewRatio=1 -XX:MaxMetaspaceSize=256m -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow"
ENV PATH /usr/share/graylog/bin:$PATH

WORKDIR /usr/share/graylog
RUN install --directory --group=graylog --owner=graylog --mode=0750 ./data ./data/journal ./data/log
COPY config ./data/config
COPY docker-entrypoint.sh /

EXPOSE 9000
VOLUME /usr/share/graylog/data
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["graylog"]
