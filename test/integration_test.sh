#!/bin/bash -ex
CREDENTIALS="admin:admin"
URL="http://127.0.0.1:9000"

CURL=(curl -u "${CREDENTIALS}")
TEST_DIR="$(dirname "${0}")"
DOCKER_COMPOSE=(docker-compose -f "${TEST_DIR}/docker-compose.yml")

"${DOCKER_COMPOSE[@]}" config --quiet
"${DOCKER_COMPOSE[@]}" up --detach --quiet-pull

"${CURL[@]}" -H 'Accept: application/json' "${URL}/api/?pretty=true"
