#!/bin/sh
set -eu

# Get name of the container
HOSTNAME=$(hostname)

# Replace $REPLACE in index.html with the actual hostname
sed -i "s|\$REPLACE|$HOSTNAME|g" /usr/share/caddy/index.html

# Start Caddy
exec caddy run --config /usr/share/caddy/Caddyfile --adapter caddyfile