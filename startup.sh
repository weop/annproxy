#!/bin/bash
set -e

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Start WireGuard
wg-quick up wg0

# 1. Force a safe MTU (Standard is 1420, but 1280 prevents almost all fragmentation issues)
ip link set dev wg0 mtu 1280

# 2. HARDCODE the MSS to 1200. 
# Do NOT use --clamp-mss-to-pmtu.
# 1280 (MTU) - 40 (IP+TCP headers) = 1240. We use 1220 to be safe.
iptables -t mangle -A OUTPUT -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1220
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1220

# Check if WireGuard is up
if ! wg show wg0 > /dev/null 2>&1; then
    echo "Failed to start WireGuard"
    exit 1
fi

echo "WireGuard connected successfully"
wg show wg0

# Configure DNS for the container to use through WireGuard
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Ensure all traffic goes through WireGuard interface
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT

# Force tinyproxy to use WireGuard interface
iptables -t mangle -N DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark 1
iptables -t mangle -A DIVERT -j ACCEPT
iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
iptables -t mangle -A PREROUTING -p tcp --dport 9990 -j ACCEPT

# --- NEW: Exclude Local/Docker Networks from VPN Routing ---
# If the destination is Private (Local LAN or Docker), SKIP the marking
iptables -t mangle -A OUTPUT -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A OUTPUT -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A OUTPUT -d 192.168.0.0/16 -j RETURN
# -----------------------------------------------------------

# Apply Mark to everything else (The Internet)
iptables -t mangle -A OUTPUT -p tcp -m owner --uid-owner tinyproxy -j MARK --set-mark 2

# Start tinyproxy
echo "Starting tinyproxy..."
tinyproxy -c /etc/tinyproxy/tinyproxy.conf

# Test connectivity
echo "Testing connectivity..."
ping -c 2 1.1.1.1 || echo "Warning: Cannot ping through tunnel"

# Keep container running
echo "Setup complete. Container is running."
tail -f /dev/null
