#!/bin/bash

echo "===== DEBUGGING WIREGUARD CONFIG ====="
echo "Content of /etc/wireguard/wg0.conf:"
cat /etc/wireguard/wg0.conf
echo ""

echo "Hexdump of /etc/wireguard/wg0.conf:"
hexdump -C /etc/wireguard/wg0.conf
echo ""

echo "Character-by-character analysis with cat -A:"
cat -A /etc/wireguard/wg0.conf
echo ""

echo "Testing direct creation of config file inside container:"
cat > /etc/wireguard/wg0.conf.direct << EOF
[Interface]
PrivateKey=6I7TZhe9R4QKHG7KJbwVIuirxZGKyuGtpme9OznhuFE=
Address=10.74.134.13/32

[Peer]
PublicKey=sFHv/qzG7b6ds5pow+oAR3G5Wqp9eFbBD3BmEGBuUWU=
AllowedIPs=0.0.0.0/0
Endpoint=146.70.199.194:3498
EOF
echo ""

echo "Attempting to start WireGuard with directly created config:"
cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.original
cp /etc/wireguard/wg0.conf.direct /etc/wireguard/wg0.conf
wg-quick up wg0 || echo "WireGuard failed to start"

# Start tinyproxy
echo "Starting tinyproxy..."
tinyproxy -c /etc/tinyproxy/tinyproxy.conf &

# Keep container running
echo "Container is running in debug mode. Check logs for details."
tail -f /dev/null