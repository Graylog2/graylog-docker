#!/bin/bash

set -e

# save the settings over the docker(-compose) environment
__GRAYLOG_SERVER_JAVA_OPTS=${GRAYLOG_SERVER_JAVA_OPTS}

# shellcheck disable=SC1091
source /etc/profile

# and add the previos saved settings to our defaults
if [[ ! -z ${__GRAYLOG_SERVER_JAVA_OPTS} ]]
then
  echo "adding environment opts"
  GRAYLOG_SERVER_JAVA_OPTS="${GRAYLOG_SERVER_JAVA_OPTS} ${__GRAYLOG_SERVER_JAVA_OPTS}"
  export GRAYLOG_SERVER_JAVA_OPTS
fi

if [ "${1:0:1}" = '-' ]; then
  set -- graylog "$@"
fi

# Delete outdated PID file
[[ -e /tmp/graylog.pid ]] && rm --force /tmp/graylog.pid

# Create data directories
if [[ "$1" = 'graylog' ]] && [[ "$(id -u)" = '0' ]]; then
  for d in journal log plugin config contentpacks; do
    dir=${GRAYLOG_HOME}/data/$d
    [[ -d "${dir}" ]] || mkdir -p "${dir}"
  done

  chown --recursive "${GRAYLOG_USER}":"${GRAYLOG_GROUP}" "${GRAYLOG_HOME}/data"

  # Start Graylog server
  # shellcheck disable=SC2086
  set -- gosu ${GRAYLOG_USER} "${JAVA_HOME}/bin/java" ${GRAYLOG_SERVER_JAVA_OPTS} \
      -jar \
      -Dlog4j.configurationFile=${GRAYLOG_HOME}/data/config/log4j2.xml \
      -Djava.library.path=${GRAYLOG_HOME}/lib/sigar/ \
      -Dgraylog2.installation_source=docker \
      ${GRAYLOG_HOME}/graylog.jar \
      server \
      -f ${GRAYLOG_HOME}/data/config/graylog.conf ${GRAYLOG_SERVER_OPTS}
fi

# Allow the user to run arbitrarily commands like bash
exec "$@" 2>&1
