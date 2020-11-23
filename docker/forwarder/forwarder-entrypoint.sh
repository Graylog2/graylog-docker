#!/bin/bash

set -e

if [[ ! -z ${FORWARDER_SERVER_HOSTNAME} ]]
then
  echo "adding forwarder_server_hostname to forwarder.conf"
  sed -i "s/^forwarder_server_hostname =$/forwarder_server_hostname = ${FORWARDER_SERVER_HOSTNAME}/g" /etc/graylog/forwarder/forwarder.conf
fi

if [[ ! -z ${FORWARDER_GRPC_TLS_TRUST_CHAIN_CERT_FILE} ]]
then
  echo "adding forwarder_grpc_tls_trust_chain_cert_file to forwarder.conf"
  sed -i "s/^forwarder_grpc_tls_trust_chain_cert_file =$/forwarder_grpc_tls_trust_chain_cert_file = ${FORWARDER_GRPC_TLS_TRUST_CHAIN_CERT_FILE//\//\\/}/g" /etc/graylog/forwarder/forwarder.conf
fi

if [[ ! -z ${FORWARDER_GRPC_API_TOKEN} ]]
then
  echo "adding forwarder_grpc_api_token to forwarder.conf"
  sed -i "s/^forwarder_grpc_api_token =$/forwarder_grpc_api_token = ${FORWARDER_GRPC_API_TOKEN}/g" /etc/graylog/forwarder/forwarder.conf
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


exec /usr/share/graylog-forwarder/bin/graylog-forwarder run -f /etc/graylog/forwarder/forwarder.conf
