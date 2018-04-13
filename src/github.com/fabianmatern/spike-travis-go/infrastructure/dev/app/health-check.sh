#!/usr/bin/env sh

set -e

HOST=${HOST:-localhost}
PORT=${PORT:-8080}

curl "http://$HOST:$PORT/.well-known/live" --fail --show-error --silent --user-agent "health-check.sh from container" || exit 1
curl "http://$HOST:$PORT/.well-known/ready" --fail --show-error --silent --user-agent "health-check.sh from container" || exit 1
