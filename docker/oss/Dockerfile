ARG JAVA_VERSION_MAJOR=8

# layer for download and verifying
FROM ubuntu:jammy as graylog-downloader

ARG VCS_REF
ARG GRAYLOG_VERSION
ARG GRAYLOG_HOME=/usr/share/graylog
ARG GRAYLOG_UID=1100
ARG GRAYLOG_GID=1100

WORKDIR /tmp

# hadolint ignore=DL3008,DL3015
RUN \
  apt-get update  > /dev/null && \
  apt-get install --assume-yes \
    ca-certificates \
    curl > /dev/null

COPY build/fetch-and-extract.sh /bin/fetch-and-extract
RUN chmod +x /bin/fetch-and-extract

RUN fetch-and-extract \
    "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz" \
    "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz.sha256.txt" \
    "https://packages.graylog2.org/releases/graylog/graylog-integrations-plugins-${GRAYLOG_VERSION}.tgz" \
    "https://downloads.graylog.org/releases/graylog-integrations/graylog-integrations-plugins-${GRAYLOG_VERSION}.tgz"


RUN \
  install \
    --directory \
    --mode=0750 \
    /opt/graylog/data \
    /opt/graylog/data/journal \
    /opt/graylog/data/log \
    /opt/graylog/data/config \
    /opt/graylog/data/plugin \
    /opt/graylog/data/data

RUN mv /opt/graylog ${GRAYLOG_HOME} && chown -R ${GRAYLOG_UID}:${GRAYLOG_GID} ${GRAYLOG_HOME}
RUN mv ${GRAYLOG_HOME}/plugin ${GRAYLOG_HOME}/plugins-default
RUN install -d -o "${GRAYLOG_UID}" -g "${GRAYLOG_GID}" -m 0755 ${GRAYLOG_HOME}/plugins-merged
RUN install -d -o "${GRAYLOG_UID}" -g "${GRAYLOG_GID}" -m 0755 ${GRAYLOG_HOME}/plugin

COPY config ${GRAYLOG_HOME}/data/config

# -------------------------------------------------------------------------------------------------
#
# final layer
FROM eclipse-temurin:${JAVA_VERSION_MAJOR}-jre-jammy

ARG VCS_REF
ARG GRAYLOG_VERSION
ARG BUILD_DATE
ARG GRAYLOG_HOME=/usr/share/graylog
ARG GRAYLOG_USER=graylog
ARG GRAYLOG_UID=1100
ARG GRAYLOG_GROUP=graylog
ARG GRAYLOG_GID=1100
ARG JAVA_VERSION_MAJOR

COPY --chown=${GRAYLOG_UID}:${GRAYLOG_GID} --from=graylog-downloader ${GRAYLOG_HOME} ${GRAYLOG_HOME}

WORKDIR ${GRAYLOG_HOME}

# hadolint ignore=DL3027,DL3008
RUN \
  echo "export BUILD_DATE=${BUILD_DATE}"           >> /etc/profile.d/graylog.sh && \
  echo "export GRAYLOG_VERSION=${GRAYLOG_VERSION}" >> /etc/profile.d/graylog.sh && \
  echo "export GRAYLOG_SERVER_JAVA_OPTS='-Dlog4j2.formatMsgNoLookups=true -Djdk.tls.acknowledgeCloseNotify=true -XX:+UnlockExperimentalVMOptions -XX:NewRatio=1 -XX:MaxMetaspaceSize=256m -server -XX:+ResizeTLAB -XX:-OmitStackTraceInFastThrow'" >> /etc/profile.d/graylog.sh && \
  echo "export GRAYLOG_HOME=${GRAYLOG_HOME}"       >> /etc/profile.d/graylog.sh && \
  echo "export GRAYLOG_USER=${GRAYLOG_USER}"       >> /etc/profile.d/graylog.sh && \
  echo "export GRAYLOG_GROUP=${GRAYLOG_GROUP}"     >> /etc/profile.d/graylog.sh && \
  echo "export GRAYLOG_UID=${GRAYLOG_UID}"         >> /etc/profile.d/graylog.sh && \
  echo "export GRAYLOG_GID=${GRAYLOG_GID}"         >> /etc/profile.d/graylog.sh && \
  echo "export PATH=${GRAYLOG_HOME}/bin:${PATH}"   >> /etc/profile.d/graylog.sh && \
  apt-get update  > /dev/null && \
  apt-get install --no-install-recommends --assume-yes \
    curl \
    tini \
    libcap2-bin \
    libglib2.0-0 \
    libx11-6 \
    libnss3 \
    wait-for-it \
    fonts-dejavu \
    fontconfig > /dev/null && \
  addgroup \
    --gid "${GRAYLOG_GID}" \
    --quiet \
    "${GRAYLOG_GROUP}" && \
  adduser \
    --disabled-password \
    --disabled-login \
    --gecos '' \
    --home ${GRAYLOG_HOME} \
    --uid "${GRAYLOG_UID}" \
    --gid "${GRAYLOG_GID}" \
    --quiet \
    "${GRAYLOG_USER}" && \
  setcap 'cap_net_bind_service=+ep' "${JAVA_HOME}/bin/java" && \
  apt-get remove --assume-yes --purge \
    apt-utils > /dev/null && \
  rm -f /etc/apt/sources.list.d/* && \
  apt-get clean > /dev/null && \
  apt autoremove --assume-yes > /dev/null && \
  rm -rf \
    /tmp/* \
    /var/cache/debconf/* \
    /var/lib/apt/lists/* \
    /var/log/* \
    /usr/share/X11 \
    /usr/share/doc/* 2> /dev/null

COPY docker-entrypoint.sh /
COPY health_check.sh /

EXPOSE 9000
USER ${GRAYLOG_USER}
VOLUME ${GRAYLOG_HOME}/data
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
CMD ["server"]

# add healthcheck
HEALTHCHECK \
  --interval=10s \
  --timeout=2s \
  --retries=12 \
  CMD /health_check.sh

# -------------------------------------------------------------------------------------------------

LABEL maintainer="Graylog, Inc. <hello@graylog.com>" \
      org.label-schema.name="Graylog Docker Image" \
      org.label-schema.description="Official Graylog Docker image" \
      org.label-schema.url="https://www.graylog.org/" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="https://github.com/Graylog2/graylog-docker" \
      org.label-schema.vendor="Graylog, Inc." \
      org.label-schema.version=${GRAYLOG_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE}
