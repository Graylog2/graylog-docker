#!/bin/bash

set -e

source /etc/profile

if [ "${1:0:1}" = '-' ]; then
  set -- graylog "$@"
fi

# Delete outdated PID file
[[ -e /tmp/graylog.pid ]] && rm --force /tmp/graylog.pid

setup() {
  # Create data directories
  for d in journal log plugin config contentpacks
  do
    dir=${GRAYLOG_HOME}/data/${d}
    [[ -d "${dir}" ]] || mkdir -p "${dir}"
  done

  chown --recursive "${GRAYLOG_USER}":"${GRAYLOG_GROUP}" "${GRAYLOG_HOME}/data"
}

graylog() {

  "${JAVA_HOME}/bin/java" "${GRAYLOG_SERVER_JAVA_OPTS}" \
    -jar \
    -Dlog4j.configurationFile="${GRAYLOG_HOME}/data/config/log4j2.xml" \
    -Djava.library.path="${GRAYLOG_HOME}/lib/sigar/" \
    -Dgraylog2.installation_source=docker \
    "${GRAYLOG_HOME}/graylog.jar" \
    server \
    -f "${GRAYLOG_HOME}/data/config/graylog.conf" "${GRAYLOG_SERVER_OPTS}"
}

run() {
  setup
  graylog
}

run
