#!/bin/bash -ex


HADOLINT_VERSION='2.10.0'

hadolint() {
	docker run -i hadolint/hadolint:$HADOLINT_VERSION < $1
}

# lint all dockerfiles
hadolint docker/oss/Dockerfile
hadolint docker/enterprise/Dockerfile
hadolint docker/forwarder/Dockerfile

shellcheck \
  --external-sources \
  --exclude=SC2086,SC2236 \
  *.sh
