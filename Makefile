export GIT_SHA1=$(git rev-parse --short HEAD)
export IMAGE_NAME=graylog
export IMAGE_NAME_ENTERPRISE=${IMAGE_NAME}-enterprise
export IMAGE_NAME_FORWARDER=${IMAGE_NAME}-forwarder


default: docker_build

docker_build:
	@hooks/build

linter:
	@test/linter.sh

integration_test:
	@test/integration_test.sh

test: linter integration_test
