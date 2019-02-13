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

# check if we are inside kubernetes, Graylog should be run as statefulset and $POD_NAME env var should be defined like this
#          env:
#          - name: POD_NAME
#            valueFrom:
#              fieldRef:
#                fieldPath: metadata.name
# First stateful member is having pod name ended with -0, so 
if [[ ! -z "${POD_NAME}" ]]
then
 if echo "${POD_NAME}" | grep "\\-0$" >/dev/null
 then
   export GRAYLOG_IS_MASTER="true"
 else
   export GRAYLOG_IS_MASTER="false"
 fi
fi

# build GRAYLOG_MONGODB_URI from individual parameters
if [[ -z ${GRAYLOG_MONGODB_URI} ]]
then
  echo "initializing GRAYLOG_MONGODB_URI environment variable"
  GRAYLOG_MONGODB_URI="mongodb://"
  if [[ ! -z ${MONGODB_USERNAME} ]]
  then
    echo "adding MongoDB user and password GRAYLOG_MONGODB_URI environment variable"
    GRAYLOG_MONGODB_URI="${GRAYLOG_MONGODB_URI}${MONGODB_USERNAME}:${MONGODB_PASSWORD}@"
  fi
  if [[ ! -z ${MONGODB_URL} ]]
  then
    echo "adding MongoDB URL GRAYLOG_MONGODB_URI environment variable"
    GRAYLOG_MONGODB_URI="${GRAYLOG_MONGODB_URI}${MONGODB_URL}"
  fi
  if [[ ! -z ${MONGODB_PORT} ]]
  then
    echo "adding MongoDB port GRAYLOG_MONGODB_URI environment variable"
    GRAYLOG_MONGODB_URI="${GRAYLOG_MONGODB_URI}:${MONGODB_PORT}"
  fi
  if [[ ! -z ${MONGODB_DATABASE} ]]
  then
    echo "adding MongoDB database GRAYLOG_MONGODB_URI environment variable"
    GRAYLOG_MONGODB_URI="${GRAYLOG_MONGODB_URI}/${MONGODB_DATABASE}"
  fi
  if [[ ! -z ${MONGODB_REPLICASET} ]]
  then
    echo "adding MongoDB replicaset GRAYLOG_MONGODB_URI environment variable"
    GRAYLOG_MONGODB_URI="${GRAYLOG_MONGODB_URI}?replicaSet=${MONGODB_REPLICASET}"
  fi
  export GRAYLOG_MONGODB_URI
fi

# build GRAYLOG_ELASTICSEARCH_HOSTS from individual parameters
if [[ -z ${GRAYLOG_ELASTICSEARCH_HOSTS} ]]
then
  echo "initializing GRAYLOG_ELASTICSEARCH_HOSTS environment variable"
  GRAYLOG_ELASTICSEARCH_HOSTS="http://"
  if [[ ! -z ${ELASTICSEARCH_USERNAME} ]]
  then
    echo "adding Elasticsearch user and password GRAYLOG_ELASTICSEARCH_HOSTS environment variable"
    GRAYLOG_ELASTICSEARCH_HOSTS="${GRAYLOG_ELASTICSEARCH_HOSTS}${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}@"
  fi
  if [[ ! -z ${ELASTICSEARCH_URL} ]]
  then
    echo "adding Elasticsearch URL GRAYLOG_ELASTICSEARCH_HOSTS environment variable"
    GRAYLOG_ELASTICSEARCH_HOSTS="${GRAYLOG_ELASTICSEARCH_HOSTS}${ELASTICSEARCH_URL}"
  fi
  if [[ ! -z ${ELASTICSEARCH_PORT} ]]
  then
    echo "adding Elasticsearch port GRAYLOG_ELASTICSEARCH_HOSTS environment variable"
    GRAYLOG_ELASTICSEARCH_HOSTS="${GRAYLOG_ELASTICSEARCH_HOSTS}:${ELASTICSEARCH_PORT}"
  fi
  export GRAYLOG_ELASTICSEARCH_HOSTS
fi

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

  "${JAVA_HOME}/bin/java" \
    ${GRAYLOG_SERVER_JAVA_OPTS} \
    -jar \
    -Dlog4j.configurationFile="${GRAYLOG_HOME}/data/config/log4j2.xml" \
    -Djava.library.path="${GRAYLOG_HOME}/lib/sigar/" \
    -Dgraylog2.installation_source=docker \
    "${GRAYLOG_HOME}/graylog.jar" \
    server \
    -f "${GRAYLOG_HOME}/data/config/graylog.conf"
}

run() {
  setup
  graylog
}

run
