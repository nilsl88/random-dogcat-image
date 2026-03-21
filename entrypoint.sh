#!/bin/sh
set -eu

# Get the name of the container
HOSTNAME=$(hostname)

# Create writable runtime directories
mkdir -p /tmp/caddy-site /tmp/config /tmp/data

# Copy the site files from the image into the writable runtime directory
cp -R /usr/share/caddy/. /tmp/caddy-site/

# Replace $REPLACE in index.html with the actual hostname
sed "s|\$REPLACE|$HOSTNAME|g" /usr/share/caddy/index.html > /tmp/caddy-site/index.html

# Start Caddy using the bundled Caddyfile
exec /usr/bin/caddy run --config /usr/share/caddy/Caddyfile --adapter caddyfile