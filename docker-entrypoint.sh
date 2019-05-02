#!/bin/bash

set -e

# Delete outdated PID file
[[ -e /tmp/graylog.pid ]] && rm --force /tmp/graylog.pid

# Create data directories
for d in journal log plugin config contentpacks
do
  dir=${GRAYLOG_HOME}/data/${d}
  [[ -d "${dir}" ]] || mkdir -p "${dir}"
  
  if [[ "$(stat --format='%U:%G' $dir)" != 'graylog:graylog' ]] && [[ -w "$dir" ]]; then
    chown -R graylog:graylog "$dir" || echo "Warning can not change owner to graylog:graylog"
  fi
done

##
## Place anything above this comment that needs to be done as root before
## dropping privileges to start the graylog process.
##

exec chroot --userspec=graylog:graylog / /graylog-start.sh
