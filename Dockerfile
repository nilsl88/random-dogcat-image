FROM caddy:latest

# Copy website files
COPY . /usr/share/caddy/

# Copy and set the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chown -R 10001:10001 /usr/share/caddy /usr/local/bin/entrypoint.sh

# Run as non-root
USER 10001:10001

# Use the entrypoint script to replace $REPLACE on startup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]