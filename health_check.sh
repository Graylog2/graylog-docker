#!/bin/bash

source /etc/profile

host="$(hostname -i || echo '127.0.0.1')"

port=9000
tls=false
proto=http

# rest_listen_uri = http://0.0.0.0:9000/api/
rest_listen_uri=$(grep "rest_listen_uri" ${GRAYLOG_HOME}/data/config/graylog.conf)
#rest_enable_tls = true
tls=$(grep "^rest_enable_tls" ${GRAYLOG_HOME}/data/config/graylog.conf | awk -F '=' '{print $2}' | awk '{$1=$1};1')

[[ ! -z "${tls}" ]] && [[ ${tls} = "true" ]] && proto=https

if [[ ! -z "${GRAYLOG_WEB_ENDPOINT_URI}" ]]
then
  port=$(echo "${GRAYLOG_WEB_ENDPOINT_URI}" | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')
elif [[ ! -z "${rest_listen_uri}" ]]
then
  port=$(echo -e "${rest_listen_uri}" | awk -F '=' '{print $2}' | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')
fi

if curl --silent --fail ${proto}://${host}:${port}/api
then
  exit 0
fi

exit 1
