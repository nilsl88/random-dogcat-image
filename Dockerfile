FROM caddy:latest

# Copy website files
COPY . /usr/share/caddy/

# Copy the Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# Copy and set the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use the entrypoint script to replace $REPLACE on startup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

