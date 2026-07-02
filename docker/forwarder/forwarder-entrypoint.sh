#!/bin/bash

set -eo pipefail

# Convert all environment variables with names ending in __FILE into the content of
# the file that they point at and use the name without the trailing __FILE.
# This can be used to carry in Docker secrets.
resolve_file_secrets() {
  local PREFIX="$1"
  local VAR_NAME VAR_NAME_FILE VAR_FILENAME

  if [[ -z "$PREFIX" ]]; then
    return 0
  fi
  if [[ ! "$PREFIX" =~ ^[A-Za-z0-9_]+$ ]]; then
    echo >&2 "ERROR: Invalid env prefix '$PREFIX' (allowed characters: A-Z, a-z, 0-9, _)"
    exit 1
  fi
  for VAR_NAME in $(env | grep "^${PREFIX}[^=]\+__FILE=.\+" | sed -r "s/^(${PREFIX}[^=]*)__FILE=.*/\1/g"); do
    VAR_NAME_FILE="${VAR_NAME}__FILE"
    if [ "${!VAR_NAME+x}" ]; then
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
}

# Resolve GRAYLOG_ secrets first, then any custom-prefixed secrets. Resolving the
# custom prefix before the mirror loop below means a natively-set custom secret
# already exists and won't be overwritten by a mirrored GRAYLOG_ value.
resolve_file_secrets "GRAYLOG_"
if [ "${CUSTOM_ENV_PREFIX}" ]; then
  resolve_file_secrets "${CUSTOM_ENV_PREFIX}"
fi

# Re-export GRAYLOG_ prefixed env setting overrides if this Docker image build uses a different ENV_PREFIX
if [ "${CUSTOM_ENV_PREFIX}" ]; then
  for UNPREFIXED_VAR_NAME in $(env | grep '^GRAYLOG_[^=]*=' | sed -r 's/^GRAYLOG_([^=]*)=.*/\1/g'); do
    NEW_NAME="${CUSTOM_ENV_PREFIX}${UNPREFIXED_VAR_NAME}"
    # don't overwrite existing custom settings
    if [ -z "${!NEW_NAME+x}" ] ; then
      ORIG_VALUE="GRAYLOG_${UNPREFIXED_VAR_NAME}"
      echo "Copying ${UNPREFIXED_VAR_NAME} into ${NEW_NAME}"
      export "${NEW_NAME}"="${!ORIG_VALUE}"
    fi
  done
fi

# Create data and journal dir explicitly because FORWARDER_DATA_DIR could
# be mounted to an empty volume.
/usr/bin/install -d -o root -g root -m 0755 "$GRAYLOG_DATA_DIR"
/usr/bin/install -d -o root -g root -m 0755 "$GRAYLOG_MESSAGE_JOURNAL_DIR"

exec "${GRAYLOG_BIN_SCRIPT}" run -f "$FORWARDER_CONFIG_FILE"
