#!/bin/sh

# Read the hostname from /etc/hostname
HOSTNAME=$(cat /etc/hostname)

# Replace $REPLACE in index.html with the actual hostname
sed -i "s|\$REPLACE|$HOSTNAME|g" /usr/share/caddy/index.html

# Start Caddy
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile

