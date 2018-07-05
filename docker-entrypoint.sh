#!/bin/bash

set -e

if [ "${1:0:1}" = '-' ]; then
  set -- graylog "$@"
fi

# Delete outdated PID file
rm -f /tmp/graylog.pid

# Create data directories
if [ "$1" = 'graylog' ] && [ "$(id -u)" = '0' ]; then
  for d in journal log plugin config contentpacks; do
    dir=/usr/share/graylog/data/$d
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
    fi
    if [[ "$(stat --format='%U:%G' $dir)" != 'graylog:graylog' ]] && [[ -w "$dir" ]]; then
      chown -R graylog:graylog "$dir"
    fi
  done

  # Convert all environment variables with names ending in __FILE into the content of
  # the file that they point at and use the name without the trailing __FILE.
  # This can be used to carry in Docker secrets.
  for VAR_NAME in $(env | grep '^GRAYLOG_[^=]\+__FILE=.\+' | sed -r 's/^(GRAYLOG_[^=]*)__FILE=.*/\1/g'); do
    VAR_NAME_FILE="${VAR_NAME}__FILE"
    if [ "${!VAR_NAME}" ]; then
      echo >&2 "ERROR: Both ${VAR_NAME} and ${VAR_NAME_FILE} are set but are exclusive"
      exit 1
    fi
    VAR_FILENAME="${!VAR_NAME_FILE}"
    echo "Getting secret ${VAR_NAME} from ${VAR_FILENAME}"
    if [ ! -r "${VAR_FILENAME}" ]; then
      echo >&2 "ERROR: ${VAR_FILENAME} does not exist or is not readable"
      exit 1
    fi
    export "${VAR_NAME}"="$(< "${VAR_FILENAME}")"
    unset "${VAR_NAME_FILE}"
  done

  # Start Graylog server
  # shellcheck disable=SC2086
  set -- gosu graylog "$JAVA_HOME/bin/java" $GRAYLOG_SERVER_JAVA_OPTS \
      -jar \
      -Dlog4j.configurationFile=/usr/share/graylog/data/config/log4j2.xml \
      -Djava.library.path=/usr/share/graylog/lib/sigar/ \
      -Dgraylog2.installation_source=docker /usr/share/graylog/graylog.jar \
      server \
      -f /usr/share/graylog/data/config/graylog.conf ${GRAYLOG_SERVER_OPTS}
fi

# Allow the user to run arbitrarily commands like bash
exec "$@"
