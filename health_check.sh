#!/bin/bash

source /etc/profile

host="$(hostname -i || echo '127.0.0.1')"

port=9000
tls=false
proto=http

# rest_listen_uri = http://0.0.0.0:9000/api/
http_bind_address=$(grep "http_bind_address" ${GRAYLOG_HOME}/data/config/graylog.conf)
#rest_enable_tls = true
tls=$(grep "^http_enable_tls" ${GRAYLOG_HOME}/data/config/graylog.conf | awk -F '=' '{print $2}' | awk '{$1=$1};1')

[[ ! -z "${tls}" ]] && [[ ${tls} = "true" ]] && proto=https

if [[ ! -z "${GRAYLOG_HTTP_BIND_ADDRESS}" ]]
then
  port=$(echo "${GRAYLOG_HTTP_BIND_ADDRESS}" | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')
elif [[ ! -z "${http_bind_address}" ]]
then
  port=$(echo -e "${http_bind_address}" | awk -F '=' '{print $2}' | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')
fi

if curl --silent --fail ${proto}://${host}:${port}/api
then
  exit 0
fi

exit 1
