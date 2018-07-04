#!/bin/bash -ex
HADOLINT_VERSION='1.9.0'
HADOLINT_PATH='/usr/local/bin/hadolint'
if ! [ -x "$(command -v hadolint)" ]; then
  wget -O "${HADOLINT_PATH}" "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64"
  chmod +x "${HADOLINT_PATH}"
fi

hadolint Dockerfile
shellcheck docker-entrypoint.sh
