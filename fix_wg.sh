#!/bin/sh
set -e

# Create a custom startup script that doesn't use wg-quick
cat > /home/vi/Containers/annproxy/manual_wg.sh << 'EOF'
#!/bin/bash

# Debug info
echo "===== Manual WireGuard Setup ====="

# Create the interface manually
echo "Creating WireGuard interface manually..."
ip link add dev wg0 type wireguard
ip address add 10.74.134.13/32 dev wg0
wg set wg0 private-key <(echo "6I7TZhe9R4QKHG7KJbwVIuirxZGKyuGtpme9OznhuFE=")
wg set wg0 peer "sFHv/qzG7b6ds5pow+oAR3G5Wqp9eFbBD3BmEGBuUWU=" allowed-ips 0.0.0.0/0 endpoint "146.70.199.194:3498"

# Bring up the interface
ip link set wg0 up
ip route add default dev wg0

# Verification
echo "WireGuard interface status:"
wg show

# Continue with tinyproxy and the rest of the startup
echo "Starting tinyproxy..."
tinyproxy -c /etc/tinyproxy/tinyproxy.conf &

# Enable IP forwarding and iptables rules
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT

# Force tinyproxy to use WireGuard interface
iptables -t mangle -N DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark 1
iptables -t mangle -A DIVERT -j ACCEPT
iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
iptables -t mangle -A PREROUTING -p tcp --dport 9990 -j ACCEPT
iptables -t mangle -A OUTPUT -p tcp -m owner --uid-owner tinyproxy -j MARK --set-mark 2
ip rule add fwmark 2 lookup 200
ip route add default dev wg0 table 200

echo "Container is running with manually configured WireGuard."
tail -f /dev/null
EOF

chmod +x /home/vi/Containers/annproxy/manual_wg.sh

# Update the Dockerfile to use our manual script
cat > /home/vi/Containers/annproxy/Dockerfile << 'EOF'
FROM alpine:latest

# Install WireGuard, iptables, and proxy tools
RUN apk add --no-cache \
    wireguard-tools \
    iptables \
    tinyproxy \
    openrc \
    bash \
    iproute2 \
    procps

# Create directories
RUN mkdir -p /etc/wireguard \
    && mkdir -p /var/log \
    && touch /var/log/tinyproxy.log \
    && chown tinyproxy:tinyproxy /var/log/tinyproxy.log

# Copy tinyproxy configuration
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf

# Copy startup script
COPY manual_wg.sh /startup.sh
RUN chmod +x /startup.sh

# Expose proxy port
EXPOSE 9990

# Run startup script
CMD ["/startup.sh"]
EOF

# Update the docker-compose file to not mount the config
cat > /home/vi/Containers/annproxy/compose.yml << 'EOF'
version: '3'

services:
  annproxy:
    build: .
    container_name: annproxy
    privileged: true
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv6.conf.all.disable_ipv6=0
    ports:
      - "9990:9990"
    restart: unless-stopped
EOF

echo "New files created. Please rebuild and restart your container:"
echo "docker-compose down && docker-compose build && docker-compose up -d"