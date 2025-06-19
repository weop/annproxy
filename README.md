# AnnProxy: WireGuard Proxy

This container creates a WireGuard connection and exposes an HTTP proxy on port 9990.

> "The sun is the same in a relative way, but the heat is different."


## Quick Start

1. Build and run the container:
```bash
podman-compose up -d
```

2. Configure your browser to use the HTTP(S) proxy:
   - Proxy Address: `localhost`
   - Port: `9990`

3. All browser traffic will now go through the WireGuard.

## Manual Build & Run

```bash
# Build the container
podman build -t annproxy .

# Run the container
podman run -d \
  --name annproxy \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl net.ipv4.ip_forward=1 \
  -p 9990:9990 \
  -v ./wg.conf:/etc/wireguard/wg0.conf:ro \
  annproxy
```

## Check Container Logs

```bash
podman logs annproxy
```

## Stop and Remove

```bash
podman-compose down
```


## TODO

1. Sock5
2. DNS