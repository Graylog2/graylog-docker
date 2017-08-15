#!/bin/bash

set -e

if [ "${1:0:1}" = '-' ]; then
  set -- graylog "$@"
fi

# Delete outdated PID file
rm -f /tmp/graylog.pid

# Create data directories
if [ "$1" = 'graylog' -a "$(id -u)" = '0' ]; then
  for d in journal log plugin config contentpacks; do
    dir=/usr/share/graylog/data/$d
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
    fi
    if [ "$(stat --format='%U:%G' $dir)" != 'graylog:graylog' ]; then
      chown -R graylog:graylog "$dir"
    fi
  done
  # Start Graylog server
  set -- su-exec graylog "$JAVA_HOME/bin/java" $GRAYLOG_SERVER_JAVA_OPTS \
      -jar \
      -Dlog4j.configurationFile=/usr/share/graylog/data/config/log4j2.xml \
      -Djava.library.path=/usr/share/graylog/lib/sigar/ \
      -Dgraylog2.installation_source=docker /usr/share/graylog/graylog.jar \
      server \
      -f /usr/share/graylog/data/config/graylog.conf
fi

# Allow the user to run arbitrarily commands like bash
exec "$@"
