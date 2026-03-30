#!/bin/bash

set -e

# save the settings over the docker(-compose) environment
__GRAYLOG_SERVER_JAVA_OPTS=${GRAYLOG_SERVER_JAVA_OPTS}

# shellcheck disable=SC1091
source /etc/profile

# and add the previous saved settings to our defaults
if [[ ! -z ${__GRAYLOG_SERVER_JAVA_OPTS} ]]
then
  echo "adding environment opts"
  GRAYLOG_SERVER_JAVA_OPTS="${GRAYLOG_SERVER_JAVA_OPTS} ${__GRAYLOG_SERVER_JAVA_OPTS}"
  export GRAYLOG_SERVER_JAVA_OPTS
fi

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
   export GRAYLOG_IS_LEADER="true"
 else
   export GRAYLOG_IS_LEADER="false"
 fi
fi

# check if we are inside a nomad cluster
# First member is having alloc-index 0, so
if [[ ! -z "${NOMAD_ALLOC_INDEX}" ]]; then
  if [ ${NOMAD_ALLOC_INDEX} == 0 ]; then
    export GRAYLOG_IS_LEADER="true"
  else
    export GRAYLOG_IS_LEADER="false"
  fi
fi

# Merge plugin dirs to allow mounting of /plugin as a volume
export GRAYLOG_PLUGIN_DIR=${GRAYLOG_HOME}/plugins-merged
rm -f ${GRAYLOG_PLUGIN_DIR}/*
find ${GRAYLOG_HOME}/plugins-default/ -type f -exec cp {} ${GRAYLOG_PLUGIN_DIR}/ \;
find ${GRAYLOG_HOME}/plugin ! -readable -prune -o -type f -a -readable -exec cp {} ${GRAYLOG_PLUGIN_DIR}/ \;


setup() {
  # Create data directories
  for d in config contentpacks data journal scripts
  do
    dir=${GRAYLOG_HOME}/data/${d}
    [[ -d "${dir}" ]] || mkdir -p "${dir}"

    if [[ "$(stat --format='%U:%G' $dir)" != 'graylog:graylog' ]] && [[ -w "$dir" ]]; then
      chown -R graylog:graylog "$dir" || echo "Warning can not change owner to graylog:graylog"
    fi
  done
}

setupCertificates() {
  # Add custom certificates to store
  # Changing the original files requires write permissions, which is not possible
  # in a container with read-only filesystem and/or non-root container.
  if [ -d /certificates ] && [ "$(ls -A /certificates)" ]; then
    DEFAULTTRUSTSTORE="$JAVA_HOME"/lib/security/cacerts

    # Import default keystore into custom keystore
    keytool -importkeystore -destkeystore "/tmp/custom.keystore" -srckeystore "${DEFAULTTRUSTSTORE}" -srcstorepass changeit -deststorepass changeit -noprompt
    # Import the additional certificate into JVM truststore if it doesn't exist
    for i in /certificates/*crt; do
      if [ ! -f "$i" ]; then
        continue
      fi
      if ! keytool -list -keystore /tmp/custom.keystore -alias "$(basename "$i" .crt)" -storepass changeit > /dev/null; then
        keytool -import -noprompt -alias "$(basename "$i" .crt)" -file "$i" -keystore "/tmp/custom.keystore" -storepass changeit
      fi
    done
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS} -Djavax.net.ssl.trustStore=/tmp/custom.keystore -Djavax.net.ssl.trustStorePassword=changeit"
  fi
}

graylog() {
  local log_config="${GRAYLOG_HOME}/config/log4j2.xml"
  local graylog_config="${GRAYLOG_HOME}/config/graylog.conf"
  local legacy_log_config="${GRAYLOG_HOME}/data/config/log4j2.xml"
  local legacy_graylog_config="${GRAYLOG_HOME}/data/config/graylog.conf"

  # Backward compatibility for setups that have existing (and potentially custom)
  # logging and server configuration files in the data/config directory.
  # See: https://github.com/Graylog2/docker-compose/issues/99
  if [ -f "$legacy_log_config" ]; then
    echo "WARNING: Using deprecated <$legacy_log_config> file. Switch to <$log_config>!"
    log_config="$legacy_log_config"
  fi
  if [ -f "$legacy_graylog_config" ]; then
    echo "WARNING: Using deprecated <$legacy_graylog_config> file. Switch to <$graylog_config>!"
    graylog_config="$legacy_graylog_config"
  fi

  exec "${JAVA_HOME}/bin/java" \
    ${GRAYLOG_SERVER_JAVA_OPTS} \
    -jar \
    -Dlog4j.configurationFile="${log_config}" \
    -Dgraylog2.installation_source=docker \
    "${GRAYLOG_HOME}/graylog.jar" \
    "$@" \
    -f "${graylog_config}"
}

run() {
  setup
  setupCertificates

  # if being called without an argument assume "server" for backwards compatibility
  if [ $# = 0 ]; then
    graylog server "$@"
  fi

  graylog "$@"
}

run "$@"
