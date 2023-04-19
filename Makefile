export GIT_SHA1=$(git rev-parse --short HEAD)

default: docker_build

docker_build:
	cd docker/oss && IMAGE_NAME=graylog hooks/build
	cd docker/enterprise && IMAGE_NAME=graylog-enterprise hooks/build
	cd docker/forwarder && IMAGE_NAME=graylog-forwarder hooks/build
	cd docker/datanode && IMAGE_NAME=graylog-datanode hooks/build

linter:
	@test/linter.sh

integration_test:
	@test/integration_test.sh

test: linter integration_test
