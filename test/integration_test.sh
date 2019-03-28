#!/bin/bash

set -u

GRAYLOG_PORT=9000

CREDENTIALS="admin:admin"
URL="http://127.0.0.1:9000"

TEST_DIR="$(dirname "${0}")"

# -------------------------------------------------------------------------------------------------

finish() {
  rv=$?
  if [ ${rv} -gt 0 ]
  then
    echo -e "\033[38;5;202m\033[1mexit with signal '${rv}'\033[0m"

    docker-compose down
  fi

  rm test/*_result.json 2> /dev/null

  exit $rv
}

trap finish SIGINT SIGTERM INT TERM EXIT

# -------------------------------------------------------------------------------------------------


JQ_VERSION='1.6'
JQ_PATH='/usr/local/bin/jq'
if ! [ -x "$(command -v jq)" ]; then
  sudo wget -O "${JQ_PATH}" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
  sudo chmod +x "${JQ_PATH}"
fi

NC=$(command -v  ncat)
NC_OPTS="-z"

if [[ -z "${NC}" ]]
then
  NC=$(command -v nc)
  NC_OPTS=
fi


compose_up() {

  cat << EOF > .env
VCS_REF=$(git rev-parse --short HEAD)
GRAYLOG_VERSION=$(cat ${PWD}/../VERSION)
EOF

  docker-compose --file docker-compose.tpl config  > ./docker-compose.yml
  docker-compose build
  docker-compose up -d
}

compose_down() {

  # Shutdown
  docker-compose down
}

wait_for_port() {

  echo "wait for graylog port ${GRAYLOG_PORT}"

  RETRY=40
  until [[ ${RETRY} -le 0 ]]
  do
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/${GRAYLOG_PORT}" 2> /dev/null
    if [ $? -eq 0 ]
    then
      break
    else
      sleep 3s
      RETRY=$(expr ${RETRY} - 1)
    fi
  done

  if [[ $RETRY -le 0 ]]
  then
    echo "could not connect to the graylog instance"
    exit 1
  fi
}


wait_for_application() {

  c=0
  echo 'Waiting until Graylog has been started'
  until curl --silent --head "${URL}"
  do
    # Only 10 retries
    ((c++)) && ((c==10)) && (echo "Couldn't reach Graylog via network" ; exit 1)
    sleep 10s
  done

  curl \
    --silent \
    --user "${CREDENTIALS}" \
    --header 'Accept: application/json' \
    "${URL}/api/?pretty=true"

  sleep 2s
}


cluster_state() {

  echo -e "\nget cluster state with session"
  code=$(curl \
    --silent \
    --request POST \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --header 'X-Requested-By: cli' \
    --output session_result.json \
    --write-out '%{http_code}\n' \
    --data '{"username":"admin", "password":"admin", "host":""}' \
    "${URL}/api/system/sessions")

  result=${?}

  if [ ${result} -eq 0 ] && [ ${code} -eq 200 ] || [ ${code} -eq 201 ]
  then
    session_id=$(jq --raw-output '.session_id' session_result.json)

    curl \
      --silent \
      --user "${session_id}:session" \
      --header 'Accept: application/json' \
      "${URL}/api/cluster?pretty=true"

  else
    echo "code: ${code}"
    cat session_result.json
    jq --raw-output '.message' session_result.json 2> /dev/null
  fi

}

create_roles() {

  echo -e "\ncreate permissions to create dashboards"
  code=$(curl \
    --silent \
    --user "${CREDENTIALS}" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --header 'X-Requested-By: cli' \
    --output permissions_result.json \
    --write-out '%{http_code}\n' \
    --data @permissions-dashboard.json \
    "${URL}/api/roles")

  result=${?}

  if [ ${result} -eq 0 ] && [ ${code} -eq 200 ] || [ ${code} -eq 201 ]
  then
    echo "successful"
  else
    echo "code: ${code}"
    cat permissions_result.json
    jq --raw-output '.message' permissions_result.json 2> /dev/null
  fi

  rm -f permissions_result.json
}

create_input_streams() {

  echo -e "\nimport input stream for plaintext"
  # Create Raw/Plaintext TCP input
  code=$(curl \
    --silent \
    --user "${CREDENTIALS}" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --header 'X-Requested-By: curl' \
    --output input_plaintext_result.json \
    --data @input-raw-tcp.json \
    --write-out '%{http_code}\n' \
    "${URL}/api/system/inputs?pretty=true")

  if [ ${result} -eq 0 ] && [ ${code} -eq 200 ] || [ ${code} -eq 201 ]
  then
    echo "successful"
  else
    echo "code: ${code}"
    cat input_plaintext_result.json
    jq --raw-output '.message' input_plaintext_result.json 2> /dev/null
  fi

  echo -e "\nimport input stream for syslog"
  # Create Syslog TCP input
  code=$(curl \
    --silent \
    --user "${CREDENTIALS}" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --header 'X-Requested-By: curl' \
    --output input_syslog_result.json \
    --write-out '%{http_code}\n' \
    --data @input-syslog-tcp.json \
    "${URL}/api/system/inputs?pretty=true")

  if [ ${result} -eq 0 ] && [ ${code} -eq 200 ] || [ ${code} -eq 201 ]
  then
    echo "successful"
  else
    echo "code: ${code}"
    cat input_syslog_result.json
    jq --raw-output '.message' input_plaintext_result.json 2> /dev/null
  fi

  sleep 2
}

send_messages() {

  echo -e "\nsend message to RAW input stream"

  # Send message to Raw/Plaintext TCP input
  echo 'plaintext' | nc -w5 127.0.0.1 5555

  echo -e "send message to syslog input stream"
  # Send message to Syslog TCP input
  echo '<0>1 2018-07-04T12:00:00.000Z test.example.com test - - - syslog' | nc -w5 127.0.0.1 514

  sleep 2s
}

validate_messages() {

  echo -e "\ncheck received messages"
  # Check messages received by Raw/Plaintext TCP input
  TOTAL_MESSAGES=$(curl \
    --silent \
    --user "${CREDENTIALS}" \
    --header 'Accept: application/json' \
    "${URL}/api/search/universal/relative/?pretty=true&query=plaintext&range=0" | jq '.total_results')

  echo "plaintext messages found: '${TOTAL_MESSAGES}'"

  if [ "${TOTAL_MESSAGES}" -ne 1 ]
  then
    echo "Expected to find 1 message from Raw/Plaintext TCP input"
    exit 1
  fi

  # Check messages received by Syslog TCP input
  TOTAL_MESSAGES=$(curl \
    --silent \
    --user "${CREDENTIALS}" \
    --header 'Accept: application/json' \
    "${URL}/api/search/universal/relative/?pretty=true&query=syslog&range=0" | jq '.total_results')

  echo "syslog messages found: '${TOTAL_MESSAGES}'"

  if [ "${TOTAL_MESSAGES}" -ne 1 ]
  then
    echo "Expected to find 1 message from Syslog TCP input"
    exit 1
  fi

  echo ""
}

inspect() {

  echo ""
  echo "inspect needed containers"
  for d in $(docker ps | tail -n +2 | awk  '{print($1)}')
  do
    # docker inspect --format "{{lower .Name}}" ${d}
    c=$(docker inspect --format '{{with .State}} {{$.Name}} has pid {{.Pid}} {{end}}' ${d})
    s=$(docker inspect --format '{{json .State.Health }}' ${d} | jq --raw-output .Status)

    printf "%-40s - %s\n"  "${c}" "${s}"
  done
}

run() {

  pushd test > /dev/null

  compose_up

  wait_for_port
  wait_for_application
  inspect
  cluster_state
  create_roles
  create_input_streams
  send_messages
  validate_messages

  compose_down

  popd > /dev/null
}

run

exit 0
