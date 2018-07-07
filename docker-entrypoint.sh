#!/bin/bash

set -e

if [ "${1:0:1}" = '-' ]; then
  set -- "$@"
fi

# Delete outdated PID file
rm -f /tmp/graylog.pid

# Start Graylog server
if [ "$1" = 'graylog' ]; then
  # shellcheck disable=SC2086
  set -- "$JAVA_HOME/bin/java" $GRAYLOG_SERVER_JAVA_OPTS \
      -jar \
      -Dlog4j.configurationFile=/usr/share/graylog/data/config/log4j2.xml \
      -Djava.library.path=/usr/share/graylog/lib/sigar/ \
      -Dgraylog2.installation_source=docker /usr/share/graylog/graylog.jar \
      server \
      -f /usr/share/graylog/data/config/graylog.conf ${GRAYLOG_SERVER_OPTS}
fi

# Allow the user to run arbitrarily commands like bash
exec "$@"
