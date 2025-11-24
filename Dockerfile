FROM alpine:latest

# Install WireGuard, iptables, and proxy tools
RUN apk add --no-cache \
    wireguard-tools \
    iptables \
    tinyproxy \
    bash \
    iproute2

# Create directories
RUN mkdir -p /etc/wireguard \
    && mkdir -p /var/log \
    && touch /var/log/tinyproxy.log \
    && chown tinyproxy:tinyproxy /var/log/tinyproxy.log

# Copy tinyproxy configuration
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Expose proxy port
EXPOSE 9990

# Run startup script
CMD ["/startup.sh"]
