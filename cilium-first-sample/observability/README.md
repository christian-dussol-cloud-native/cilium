# Hubble Observability

Hubble provides deep network observability for Cilium-managed Kubernetes clusters, powered by eBPF.

---

## Quick Start

### 1. Install Hubble

```bash
chmod +x install-hubble.sh
./install-hubble.sh
```

### 2. Start Port Forwarding (Terminal 1)

```bash
cilium hubble port-forward
```

> Keep this terminal open - it maintains the connection to Hubble.

### 3. Start Hubble UI (Terminal 2)

```bash
cilium hubble ui
```

> Keep this terminal open - it serves the web interface.

### 4. Access Hubble UI

Open your browser at: **http://localhost:12000**

### 5. Generate Traffic (Terminal 3)

```bash
# Generate some test traffic
kubectl exec test-pod-a -- curl http://test-service-b
kubectl exec test-pod-a -- curl http://test-service-b
kubectl exec test-pod-a -- curl http://test-service-b
```

### 6. Monitor in Hubble UI

Select your Kubernetes namespace (e.g., `default`) in the UI to visualize the traffic flow.

---

## Terminal Setup Summary

| Terminal | Command | Purpose |
|----------|---------|---------|
| Terminal 1 | `cilium hubble port-forward` | gRPC connection to Hubble |
| Terminal 2 | `cilium hubble ui` | Web UI server |
| Terminal 3 | `hubble observe --follow` | CLI monitoring |

---

## Hubble CLI Commands

### Basic Monitoring

```bash
# Watch all traffic in real-time
hubble observe --follow

# Watch specific namespace
hubble observe -n default --follow

# Watch specific pod
hubble observe --pod test-pod-a --follow

# Show last N flows
hubble observe --last 100
```

### Security Monitoring

```bash
# Show only dropped traffic (policy violations)
hubble observe --verdict DROPPED

# Show dropped traffic in real-time
hubble observe --verdict DROPPED --follow

# Show HTTP traffic only
hubble observe --protocol http

# Show DNS traffic
hubble observe --protocol dns
```

### Troubleshooting

```bash
# Check Hubble status
hubble status

# Check Cilium status
cilium status
```

---

## What You Can See

### In Hubble UI
- Service dependency graph
- Traffic flows between pods
- Allowed vs dropped connections
- HTTP request/response details
- DNS queries

### In Hubble CLI
- Real-time network flows
- Source and destination pods/services
- Verdict (FORWARDED, DROPPED, AUDIT)
- L4 ports and protocols
- L7 HTTP methods and paths

---

## Files in This Directory

| File | Description |
|------|-------------|
| `install-hubble.sh` | Automated Hubble installation script |
| `queries.md` | 50+ Hubble CLI query examples |

---

## Resources

- [Hubble Documentation](https://docs.cilium.io/en/stable/observability/hubble/)
- [Hubble CLI Reference](https://docs.cilium.io/en/stable/observability/hubble/hubble-cli/)
- [Hubble UI Guide](https://docs.cilium.io/en/stable/observability/hubble/hubble-ui/)
