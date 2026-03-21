FROM caddy:latest

# Copy website files into the image
COPY . /usr/share/caddy/

# Copy and set the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chown -R 10001:10001 /usr/share/caddy /usr/local/bin/entrypoint.sh \
    && setcap -r /usr/bin/caddy

# Run as non-root
USER 10001:10001

# Use writable paths under /tmp for runtime data
ENV XDG_CONFIG_HOME=/tmp/config
ENV XDG_DATA_HOME=/tmp/data

# Use the entrypoint script to prepare runtime files and start Caddy
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]