#!/bin/bash

# Create a script to debug network connectivity
cat > /home/vi/Containers/annproxy/network_check.sh << 'EOF'
#!/bin/bash

echo "===== Container Network Debugging ====="

# Check if WireGuard interface is up
echo "WireGuard interface status:"
wg show || echo "WireGuard not running"
echo ""

echo "Network interfaces:"
ip addr
echo ""

echo "Routing table:"
ip route
echo ""

echo "DNS configuration:"
cat /etc/resolv.conf
echo ""

echo "Testing network connectivity:"
echo "- Ping google.com DNS:"
ping -c 3 8.8.8.8 || echo "Ping failed"
echo ""

echo "- DNS lookup:"
nslookup google.com || echo "DNS lookup failed"
echo ""

echo "- HTTP request (non-TLS):"
curl -v --max-time 5 http://example.com || echo "HTTP request failed"
echo ""

echo "- HTTPS request:"
curl -v --max-time 5 https://example.com || echo "HTTPS request failed"
echo ""

echo "Testing proxy connectivity:"
echo "- Proxy status:"
ps aux | grep tinyproxy
echo ""

echo "- Tinyproxy configuration:"
cat /etc/tinyproxy/tinyproxy.conf
echo ""

echo "- Tinyproxy logs:"
tail -n 20 /var/log/tinyproxy.log || echo "Log not found"
echo ""

echo "Iptables rules:"
iptables -L -v
echo ""
iptables -t nat -L -v
echo ""
iptables -t mangle -L -v
echo ""

echo "===== Debugging Complete ====="
EOF

chmod +x /home/vi/Containers/annproxy/network_check.sh

# Update docker-compose.yml to mount the debug script
cat > /home/vi/Containers/annproxy/debug_compose.yml << 'EOF'
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
    volumes:
      - ./network_check.sh:/network_check.sh:ro
EOF

echo "Network debugging script created."
echo "To use it:"
echo "1. Copy debug_compose.yml to compose.yml"
echo "2. Restart your container with: docker-compose up -d"
echo "3. Run the debugging script in the container: docker exec -it annproxy /network_check.sh"