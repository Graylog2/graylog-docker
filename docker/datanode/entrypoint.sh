#!/bin/bash

set -eo pipefail

# Execute the given command instead of running the datanode. (e.g., bash)
if [ "$1" != "graylog-datanode" ]; then
	exec "$@"
fi

# Convert all environment variables with names ending in __FILE into the content of
# the file that they point at and use the name without the trailing __FILE.
# This can be used to carry in Docker secrets.
for VAR_NAME in $(env | grep '^GRAYLOG_[^=]\+__FILE=.\+' | sed -r 's/^(GRAYLOG_[^=]*)__FILE=.*/\1/g'); do
	VAR_NAME_FILE="${VAR_NAME}__FILE"
	if [ "${!VAR_NAME}" ]; then
		echo >&2 "ERROR: Both ${VAR_NAME} and ${VAR_NAME_FILE} are set but are mutually exclusive"
		exit 1
	fi
	VAR_FILENAME="${!VAR_NAME_FILE}"
	echo "Getting secret ${VAR_NAME} from ${VAR_FILENAME}"
	if [ ! -r "${VAR_FILENAME}" ]; then
		echo >&2 "ERROR: ${VAR_FILENAME} does not exist or is not readable"
		exit 1
	fi
	export "${VAR_NAME}"="$(< "${VAR_FILENAME}")"
	unset VAR_NAME_FILE VAR_FILENAME
done

check_env() {
    local name="$1"

    if [ -z "${!name}" ]; then
        echo "ERROR: Missing $name environment variable"
        exit 1
    fi
}

check_env "GDN_APP_ROOT"
check_env "GDN_DATA_ROOT"
check_env "GDN_CONFIG_FILE"
check_env "GDN_FEATURE_FLAG_FILE"
check_env "GDN_JVM_OPTIONS_FILE"
check_env "GDN_USER"
check_env "GDN_GROUP"
check_env "GRAYLOG_DATANODE_PASSWORD_SECRET"
check_env "GRAYLOG_DATANODE_MONGODB_URI"

# Default Graylog settings
export GRAYLOG_DATANODE_BIN_DIR="${GDN_APP_ROOT}/bin"
export GRAYLOG_DATANODE_DATA_DIR="${GRAYLOG_DATANODE_DATA_DIR:-$GDN_DATA_ROOT}"
export GRAYLOG_DATANODE_HTTP_BIND_ADDRESS="${GRAYLOG_DATANODE_HTTP_BIND_ADDRESS:-0.0.0.0:9001}"
export GRAYLOG_DATANODE_INSTALLATION_SOURCE="${GRAYLOG_DATANODE_INSTALLATION_SOURCE:-container}"
export GRAYLOG_DATANODE_NODE_ID_FILE="${GRAYLOG_DATANODE_NODE_ID_FILE:-$GDN_DATA_ROOT/node-id}"
export GRAYLOG_DATANODE_OPENSEARCH_CONFIG_LOCATION="${GRAYLOG_DATANODE_OPENSEARCH_CONFIG_LOCATION:-"$GRAYLOG_DATANODE_DATA_DIR/opensearch/config"}"
export GRAYLOG_DATANODE_OPENSEARCH_DATA_LOCATION="${GRAYLOG_DATANODE_OPENSEARCH_DATA_LOCATION:-"$GRAYLOG_DATANODE_DATA_DIR/opensearch/data"}"
export GRAYLOG_DATANODE_OPENSEARCH_LOGS_LOCATION="${GRAYLOG_DATANODE_OPENSEARCH_LOGS_LOCATION:-"$GRAYLOG_DATANODE_DATA_DIR/opensearch/logs"}"
export GRAYLOG_DATANODE_OPENSEARCH_HTTP_PORT="${GRAYLOG_DATANODE_OPENSEARCH_HTTP_PORT:-9200}"
export GRAYLOG_DATANODE_OPENSEARCH_TRANSPORT_PORT="${GRAYLOG_DATANODE_OPENSEARCH_TRANSPORT_PORT:-9300}"
export GRAYLOG_DATANODE_NODE_NAME="${GRAYLOG_DATANODE_NODE_NAME:-"$HOSTNAME"}"

# TODO: Bundle the OpenSearch version property in the tarball so we can read it
opensearch_dist="$(find "$GDN_APP_ROOT/dist" -maxdepth 1 -name 'opensearch-*-linux-*' -type d | sort -V | tail -1)"

if [ -z "$opensearch_dist" ]; then
	echo "ERROR: No OpenSearch distribution found in $GDN_APP_ROOT/dist"
	exit 1
fi

export GRAYLOG_DATANODE_OPENSEARCH_LOCATION="$opensearch_dist"

# Settings for the graylog-datanode script
export DATANODE_JVM_OPTIONS_FILE="${DATANODE_JVM_OPTIONS_FILE:-"$GDN_JVM_OPTIONS_FILE"}"
export DATANODE_LOG4J_CONFIG_FILE="${DATANODE_LOG4J_CONFIG_FILE:-"$GDN_LOG4J_CONFIG_FILE"}"
export JAVA_OPTS="$JAVA_OPTS"

# Create required OpenSearch directories
install -d -o "$GDN_USER" -g "$GDN_GROUP" -m 0700 \
	"$GRAYLOG_DATANODE_OPENSEARCH_CONFIG_LOCATION" \
	"$GRAYLOG_DATANODE_OPENSEARCH_DATA_LOCATION" \
	"$GRAYLOG_DATANODE_OPENSEARCH_LOGS_LOCATION"

# Make sure the data node can write to the data dir
chown -R "$GDN_USER":"$GDN_GROUP" "$GRAYLOG_DATANODE_DATA_DIR"

# Starting the data node with dropped privileges
exec setpriv --reuid="$GDN_USER" --regid="$GDN_GROUP" --init-groups \
	"${GRAYLOG_DATANODE_BIN_DIR}/graylog-datanode" \
	datanode \
	-np \
	-f "$GDN_CONFIG_FILE" \
	-ff "$GDN_FEATURE_FLAG_FILE"
