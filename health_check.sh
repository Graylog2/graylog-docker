#!/bin/bash

source /etc/profile


# http://docs.graylog.org/en/3.0/pages/configuration/server.conf.html#web-rest-api
#
# if `http_publish_uri` is given, use that for healthcheck,
# if not take `http_bind_address` what defaults to 127.0.0.1
# if nothing is set.
#

# defaults
proto=http
http_bind_address=127.0.0.1:9000

# check if configuration file is given and grep for variable
if [[ -f "${GRAYLOG_HOME}"/data/config/graylog.conf ]]
then
	# try to grep the variable from a mounted configuration
	http_publish_uri=$(grep "^http_publish_uri" "${GRAYLOG_HOME}"/data/config/graylog.conf | awk -F '=' '{print $2}' | awk '{$1=$1};1')
	http_bind_address=$(grep "^http_bind_address" "${GRAYLOG_HOME}"/data/config/graylog.conf | awk -F '=' '{print $2}' | awk '{$1=$1};1')
	http_enable_tls=$(grep "^http_enable_tls" "${GRAYLOG_HOME}"/data/config/graylog.conf | awk -F '=' '{print $2}' | awk '{$1=$1};1')

	# FIX https://github.com/Graylog2/graylog-docker/issues/102
	# This will remove the protocol from the URI if set via 
	# configuration. 
	# not the smartest solution currently but a working
	# TODO: find a better way or maybe write a function
	# shellcheck disable=SC2001
	if [[ ! -z ${http_publish_uri} ]]
	then
		# remove the protocol from the URI
		proton="$(echo "${http_publish_uri}" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
		url=$(echo "${http_publish_uri}" | sed -e s,"$proton",,g)
		# we want to be sure to use https if enable
		# currently this looks like the best solution to cut
		# the protocoll away and set it based on 
		# the fact if TLS is enabled or not
		http_publish_uri="${url}"
	fi

fi

# try to get the data from environment variables
# they will always override all other settings
# shellcheck disable=SC2001
if [[ ! -z "${GRAYLOG_HTTP_PUBLISH_URI}" ]]
then
	# remove the protocol from the URI
	proton="$(echo "${GRAYLOG_HTTP_PUBLISH_URI}" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
	url=$(echo "${GRAYLOG_HTTP_PUBLISH_URI}" | sed -e s,"$proton",,g)
	# we want to be sure to use https if enable
	# currently this looks like the best solution to cut
	# the protocoll away and set it based on 
	# the fact if TLS is enabled or not
	http_publish_uri="${url}"
fi
if [[ ! -z "${GRAYLOG_HTTP_BIND_ADDRESS}" ]]
then
	http_bind_address="${GRAYLOG_HTTP_BIND_ADDRESS}"
fi
if [[ ! -z "${GRAYLOG_HTTP_ENABLE_TLS}" ]]
then
	http_enable_tls="${GRAYLOG_HTTP_ENABLE_TLS}"
fi

# if configured set https
[[ ! -z "${http_enable_tls}" ]] && [[ ${http_enable_tls} = "true" ]] && proto=https

# when HTTP_PUBLISH_URI is given that is used for the healtcheck
# otherwise HTTP_BIND_ADDRESS

if [[ ! -z "${http_bind_address}" ]]
then
	check_url="${proto}"://"${http_bind_address}"
else
	# we will never run into this - but
	# never say never
	echo "not possible to get Graylog listen URI - abort"
	exit 1
fi

if [[ ! -z "${http_publish_uri}" ]]
then
	check_url="${proto}"://"${http_publish_uri}"
fi

if [[ -z "${check_url}" ]]
then
	echo "Not possible to get Graylog listen URI - abort"
	exit 1
fi


if curl --silent --fail "${check_url}"/api
then
  	exit 0
fi

# FIX https://github.com/Graylog2/graylog-docker/issues/101
# When the above check fails fall back to localhost 
# This is not the most elegant solution but a working one
if curl --silent --fail http://127.0.0.1/api
then
  	exit 0
fi



exit 1
