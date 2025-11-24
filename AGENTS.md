# Agent Configuration for annproxy

## Project Overview
AnnProxy is a WireGuard-based HTTP proxy container that routes all traffic through a WireGuard VPN tunnel. Built on Alpine Linux using Podman/Docker.

## Build & Run Commands

### Quick Start
```bash
# Using compose (recommended)
podman-compose up -d

# Check status
podman logs annproxy
```

### Manual Build & Run
```bash
# Build container
podman build -t annproxy .

# Run container
podman run -d \
  --name annproxy \
  --privileged \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  -p 9990:9990 \
  -v ./wg_minimal.conf:/etc/wireguard/wg0.conf:ro \
  annproxy
```

### Debugging Commands
```bash
# Check logs
podman logs annproxy

# Check WireGuard status
podman exec -it annproxy wg show wg0

# Verify proxy is listening
podman exec -it annproxy nc -vz 127.0.0.1 9990

# Check routing table
podman exec -it annproxy ip route
podman exec -it annproxy ip rule

# Test connectivity through tunnel
podman exec -it annproxy ping -c 2 1.1.1.1

# Check iptables rules
podman exec -it annproxy iptables -L -v -n
podman exec -it annproxy iptables -t nat -L -v -n
podman exec -it annproxy iptables -t mangle -L -v -n

# Interactive shell
podman exec -it annproxy /bin/bash
```

### Stop & Clean Up
```bash
podman-compose down
```

## Architecture

### Container Stack
- **Base**: Alpine Linux (minimal footprint)
- **VPN**: WireGuard (wg-quick)
- **Proxy**: Tinyproxy (HTTP/HTTPS on port 9990)
- **Networking**: iptables for traffic routing

### Traffic Flow
1. Client connects to proxy on port 9990
2. Tinyproxy receives request
3. iptables rules mark tinyproxy traffic (fwmark 2)
4. ip rules route marked traffic through table 200
5. Table 200 routes all traffic through wg0 interface
6. WireGuard encrypts and sends traffic to VPN server

### Configuration Files
- `Dockerfile`: Container image definition
- `compose.yml`: Podman-compose service definition
- `startup.sh`: Container initialization script
- `tinyproxy.conf`: Proxy server configuration
- `wg.conf.sample`: WireGuard config template
- `wg_minimal.conf`: Active WireGuard configuration (gitignored)

## Code Style Guidelines

### Shell Scripts
- Use bash with `set -e` for proper error handling
- Uppercase for constants, lowercase for variables
- Echo status messages for debugging
- Test critical operations (e.g., WireGuard connection)

### Configuration Files
- Follow format of existing sample files
- Maintain consistent indentation
- Group related settings together
- Comment non-obvious configurations

### Network Routing
- Use iptables for traffic control and NAT
- Use ip rules/routes for policy-based routing
- Set fwmark for traffic marking
- Use separate routing tables for VPN traffic

### Security
- Never commit actual WireGuard credentials
- Use volume mounts for sensitive configs (`:ro` flag)
- Require privileged mode only when necessary
- Use capabilities (NET_ADMIN, SYS_MODULE) explicitly

### Error Handling
- Check command success before proceeding
- Provide clear error messages
- Log important events for debugging
- Test connectivity after setup

## Implementation Details

### Startup Process (startup.sh)
1. Enable IP forwarding
2. Start WireGuard (wg-quick up wg0)
3. Verify WireGuard is running
4. Configure DNS (1.1.1.1, 8.8.8.8)
5. Set up iptables NAT and forwarding rules
6. Create policy routing for tinyproxy traffic
7. Start tinyproxy
8. Test connectivity
9. Keep container running (tail -f /dev/null)

### Tinyproxy Configuration
- Port: 9990
- Listen: 0.0.0.0 (all interfaces)
- Timeout: 600s
- MaxClients: 100
- Logging: /var/log/tinyproxy.log (Info level)
- Access: Open to all (0.0.0.0/0)

### Required Capabilities
- `NET_ADMIN`: Network interface and routing management
- `SYS_MODULE`: Kernel module loading (WireGuard)
- `privileged`: Full container privileges for network ops

### Sysctls
- `net.ipv4.ip_forward=1`: Enable IPv4 forwarding
- `net.ipv6.conf.all.disable_ipv6=0`: Enable IPv6 (if needed)

## TODO
- [ ] Add SOCKS5 proxy support
- [ ] Implement custom DNS configuration
- [ ] Add health check endpoint
- [ ] Support multiple WireGuard configs
- [ ] Add authentication to proxy
