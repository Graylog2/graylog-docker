#!/bin/bash

set -e
set +x

CREDENTIALS="admin:admin"
URL="http://127.0.0.1:9000"

CURL=(curl -u "${CREDENTIALS}" -w '\n')
TEST_DIR="$(dirname "${0}")"
DOCKER_COMPOSE=(docker-compose -f "${TEST_DIR}/docker-compose.yml")

JQ_VERSION='1.5'
JQ_PATH='/usr/local/bin/jq'
if ! [ -x "$(command -v jq)" ]; then
  sudo wget -O "${JQ_PATH}" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
  sudo chmod +x "${JQ_PATH}"
fi

# Check docker-compose configuration and start services
"${DOCKER_COMPOSE[@]}" config --quiet
"${DOCKER_COMPOSE[@]}" up -d

echo 'Waiting until Graylog has been started'
until "${CURL[@]}" -w '' --silent --head "${URL}"
do
  # Only 10 retries
  ((c++)) && ((c==10)) && (echo "Couldn't reach Graylog via network" ; exit 1)
  sleep 10
done

"${CURL[@]}" -H 'Accept: application/json' "${URL}/api/?pretty=true"

# Create Raw/Plaintext TCP input
"${CURL[@]}" -H 'Accept: application/json' -H 'Content-Type: application/json' -H 'X-Requested-By: curl' -d @"${TEST_DIR}/input-raw-tcp.json" "${URL}/api/system/inputs?pretty=true"
# Create Syslog TCP input
"${CURL[@]}" -H 'Accept: application/json' -H 'Content-Type: application/json' -H 'X-Requested-By: curl' -d @"${TEST_DIR}/input-syslog-tcp.json" "${URL}/api/system/inputs?pretty=true"

sleep 2

# Send message to Raw/Plaintext TCP input
echo 'plaintext' | nc 127.0.0.1 5555

# Send message to Syslog TCP input
echo '<0>1 2018-07-04T12:00:00.000Z test.example.com test - - - syslog' | nc 127.0.0.1 514

sleep 2

# Check messages received by Raw/Plaintext TCP input
TOTAL_MESSAGES=$("${CURL[@]}" --silent -H 'Accept: application/json' "${URL}/api/search/universal/relative/?pretty=true&query=plaintext&range=0" | jq .total_results)
if [ "${TOTAL_MESSAGES}" -ne 1 ]; then
  echo "Expected to find 1 message from Raw/Plaintext TCP input"
  exit 1
fi

# Check messages received by Syslog TCP input
TOTAL_MESSAGES=$("${CURL[@]}" --silent -H 'Accept: application/json' "${URL}/api/search/universal/relative/?pretty=true&query=syslog&range=0" | jq .total_results)
if [ "${TOTAL_MESSAGES}" -ne 1 ]; then
  echo "Expected to find 1 message from Syslog TCP input"
  exit 1
fi

# Shutdown
"${DOCKER_COMPOSE[@]}" down
