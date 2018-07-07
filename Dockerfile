FROM openjdk:8-jre-alpine

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


ENV GRAYLOG_DIR /usr/share/graylog

ENV PATH $GRAYLOG_DIR/bin:$PATH

ENV GRAYLOG_SERVER_JAVA_OPTS "-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:NewRatio=1 -XX:MaxMetaspaceSize=256m -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow"

# fix jave in alpin
COPY etc /etc

# hadolint ignore=DL3018
RUN set -ex \
  && apk update && apk --no-cache add libcap bash \
  && setcap 'cap_net_bind_service=+ep' "$JAVA_HOME/bin/java"

RUN set -ex \
  && addgroup -g 1100 graylog \
  && adduser -D -S -g '' -u 1100 -G graylog -h "$GRAYLOG_DIR" graylog

WORKDIR /tmp
RUN set -ex \
  && wget -nv -O "/tmp/graylog-${GRAYLOG_VERSION}.tgz" "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz" \
  && wget -nv -O "/tmp/graylog-${GRAYLOG_VERSION}.tgz.sha256.txt" "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz.sha256.txt" \
  && sha256sum -c "/tmp/graylog-${GRAYLOG_VERSION}.tgz.sha256.txt" \
  && tar -xzf "/tmp/graylog-${GRAYLOG_VERSION}.tgz" --strip-components=1 -C "$GRAYLOG_DIR" \
  && rm -f "/tmp/graylog-${GRAYLOG_VERSION}.tgz.*"

WORKDIR $GRAYLOG_DIR
COPY config ./data/config

RUN set -ex \
  && mkdir -p ./data/{journal,log,plugin,config,contentpacks} \
  && chown -R graylog:graylog "$GRAYLOG_DIR"

COPY docker-entrypoint.sh /

EXPOSE 9000
USER 1100

VOLUME $GRAYLOG_DIR/data
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["graylog"]
