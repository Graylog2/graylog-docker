export GIT_SHA1=$(git rev-parse --short HEAD)
export IMAGE_NAME=graylog

default: docker_build

docker_build:
	@hooks/build
