FROM alpine:latest

# Install WireGuard, iptables, and proxy tools
RUN apk add --no-cache \
    wireguard-tools \
    iptables \
    tinyproxy \
    openrc \
    bash

# Create directories
RUN mkdir -p /etc/wireguard

# Copy WireGuard configuration
COPY wg.conf /etc/wireguard/wg0.conf

# Copy tinyproxy configuration
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Expose proxy port
EXPOSE 9990

# Run startup script
CMD ["/startup.sh"]