FROM openjdk:8-jre-stretch

ARG VCS_REF
ARG GRAYLOG_VERSION

LABEL maintainer="Graylog, Inc. <hello@graylog.com>" \
      org.label-schema.name="Graylog Docker Image" \
      org.label-schema.description="Official Graylog Docker image" \
      org.label-schema.url="https://www.graylog.org/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Graylog2/graylog-docker" \
      org.label-schema.vendor="Graylog, Inc." \
      org.label-schema.version=$GRAYLOG_VERSION \
      org.label-schema.schema-version="1.0" \
      com.microscaling.docker.dockerfile="/Dockerfile" \
      com.microscaling.license="Apache 2.0"

WORKDIR /tmp
RUN set -x \
  && mkdir /usr/share/graylog \
  && wget -nv -O "/tmp/graylog-${GRAYLOG_VERSION}.tgz" "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz" \
  && wget -nv -O "/tmp/graylog-${GRAYLOG_VERSION}.tgz.sha256.txt" "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz.sha256.txt" \
  && sha256sum -c "/tmp/graylog-${GRAYLOG_VERSION}.tgz.sha256.txt" \
  && tar -xzf "/tmp/graylog-${GRAYLOG_VERSION}.tgz" --strip-components=1 -C /usr/share/graylog \
  && rm -f "/tmp/graylog-${GRAYLOG_VERSION}.tgz" \
  && addgroup --gid 1100 graylog \
  && adduser --disabled-password --disabled-login --gecos '' --uid 1100 --gid 1100 graylog \
  && chown -R graylog:graylog /usr/share/graylog

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/jre
ENV GRAYLOG_SERVER_JAVA_OPTS "-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:NewRatio=1 -XX:MaxMetaspaceSize=256m -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow"
ENV PATH /usr/share/graylog/bin:$PATH

WORKDIR /usr/share/graylog
RUN set -x \
  && for path in \
    ./data/journal \
    ./data/log \
    ./data/config \
  ; do \
    mkdir -p "$path"; \
  done
COPY config ./data/config
COPY docker-entrypoint.sh /

EXPOSE 9000
VOLUME /usr/share/graylog/data
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["graylog"]

# hadolint ignore=DL3008
RUN set -x \
  && apt-get update && apt-get -y --no-install-recommends install \
    'gosu=1.10-*' \
    libcap2-bin \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && setcap 'cap_net_bind_service=+ep' "${JAVA_HOME}/bin/java"
