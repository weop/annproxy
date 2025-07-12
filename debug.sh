#!/bin/bash
set -e

# Create a debug version of the startup script
cat > /tmp/debug_startup.sh << 'EOF'
#!/bin/bash
set -e

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Debug information
echo "==== WireGuard Config Debug ===="
echo "Config file content:"
cat /etc/wireguard/wg0.conf
echo ""
echo "File encoding check:"
hexdump -C /etc/wireguard/wg0.conf | head -20
echo ""

# Try to start WireGuard with verbose output
echo "Attempting to start WireGuard..."
wg-quick up wg0 || echo "WireGuard failed to start"

# Start tinyproxy
echo "Starting tinyproxy..."
tinyproxy -c /etc/tinyproxy/tinyproxy.conf

# Keep container running
tail -f /dev/null
EOF

chmod +x /tmp/debug_startup.sh

# Modify docker-compose to use the debug script
sed -i 's|CMD \["/startup.sh"\]|CMD \["/tmp/debug_startup.sh"\]|' /tmp/Dockerfile.debug

echo "Debug files created"
echo "To use them:"
echo "1. docker build -f /tmp/Dockerfile.debug -t annproxy-debug ."
echo "2. Update your compose.yml to use the annproxy-debug image"
echo "3. docker-compose up"