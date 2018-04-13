#!/bin/bash

ENTRY_POINT="/docker-entrypoint.sh"

set -e

echo "$0: Starting Cassandra"
${ENTRY_POINT} cassandra &

echo "$0: Waiting for Cassandra to become available"
until /tools/health-check.sh 2>/dev/null; do
  >&2 echo "$0: Cassandra is not yet available - waiting to run initialisation scripts"; sleep 2
done

echo "$0: Cassandra is available"

echo "$0: Running initialisation scripts"
for f in docker-initdb.d/*; do
    case "$f" in
        *.sh)     echo "$0: running $f"; . "$f" ;;
        *.cql)    echo "$0: running $f"; cqlsh -f "$f";;
        *)        echo "$0: don't know what to do with $f" 1>&2; exit 1;;
    esac
done

echo "$0: Shutting down Cassandra"
pkill java

