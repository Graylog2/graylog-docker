#!/bin/bash -e

mkdir -p /tmp/download

# download
for url in "$@"; do
  file=/tmp/download/${url##*/}

  echo "fetching: $url"
  curl \
    -fsSL \
    --retry 3 \
    --retry-delay 2 \
    --output "$file" \
    "$url"
done

# verify
cd /tmp/download
for checksumfile in /tmp/download/*.sha256.txt; do
  [ -f "$checksumfile" ] && sha256sum --check "$checksumfile"
done


# extract
mkdir -p /opt/graylog

for file in /tmp/download/*.tgz; do
  echo "extracting: $file"
  tar --extract --gzip --file "$file" --strip-components=1 --directory /opt/graylog
done
