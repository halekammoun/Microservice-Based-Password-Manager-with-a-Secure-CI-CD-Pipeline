#!/usr/bin/env bash
# this script waits for the database until it's ready to accept connections

host="$1"
port="$2"
shift 2
while ! nc -z "$host" "$port"; do
  echo "Waiting for $host:$port..."
  sleep 1
done
echo "Service $host:$port is ready!"
exec "$@"
