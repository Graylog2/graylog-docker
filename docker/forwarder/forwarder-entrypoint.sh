#!/bin/bash

set -e

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


exec /usr/share/graylog-forwarder/bin/graylog-forwarder run -f /etc/graylog/forwarder/forwarder.conf
