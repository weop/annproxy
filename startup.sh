#!/bin/bash

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Start WireGuard
wg-quick up wg0

# Check if WireGuard is up
if ! wg show wg0 > /dev/null 2>&1; then
    echo "Failed to start WireGuard"
    exit 1
fi

echo "WireGuard connected successfully"

# Start tinyproxy
tinyproxy -c /etc/tinyproxy/tinyproxy.conf

# Keep container running
tail -f /dev/null