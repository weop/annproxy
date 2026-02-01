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
