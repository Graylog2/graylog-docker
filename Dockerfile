FROM openjdk:8-jre-alpine
MAINTAINER Graylog, Inc. <hello@graylog.com>

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG GRAYLOG_VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
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

RUN set -ex \
  && apk add --update su-exec openssl tar libcap wget \
  && addgroup -g 1100 graylog \
  && adduser -D -s /sbin/nologin -u 1100 -G graylog graylog \
  && mkdir /usr/share/graylog \
  && wget -nv -O /usr/share/graylog.tgz "https://packages.graylog2.org/releases/graylog/graylog-${GRAYLOG_VERSION}.tgz" \
  && tar xfz /usr/share/graylog.tgz --strip-components=1 -C /usr/share/graylog \
  && chown -R graylog:graylog /usr/share/graylog \
  && rm -f /usr/share/graylog.tgz \
  && setcap 'cap_net_bind_service=+ep' $JAVA_HOME/bin/java
  && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ENV GRAYLOG_SERVER_JAVA_OPTS "-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:NewRatio=1 -XX:MaxMetaspaceSize=256m -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow"
ENV PATH /usr/share/graylog/bin:$PATH
WORKDIR /usr/share/graylog

RUN set -ex \
  && for path in \
    ./data/journal \
    ./data/log \
    ./data/config \
  ; do \
    mkdir -p "$path"; \
  done

COPY config ./data/config

VOLUME /usr/share/graylog/data

COPY docker-entrypoint.sh /

EXPOSE 9000
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["graylog"]
