FROM registry.access.redhat.com/hi/caddy:2-builder

USER 0

# Copy website files into the image
COPY . /usr/share/caddy/

# Copy and set the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chown -R 10001:10001 /usr/share/caddy /usr/local/bin/entrypoint.sh

# Run as non-root
USER 10001:10001

# Use writable paths under /tmp for runtime data
ENV XDG_CONFIG_HOME=/tmp/config
ENV XDG_DATA_HOME=/tmp/data

STOPSIGNAL SIGTERM

# Use the entrypoint script to prepare runtime files and start Caddy
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]