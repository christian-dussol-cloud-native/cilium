# Hubble CLI Query Examples

Complete reference for network observability with Hubble CLI.

## Basic Queries

### Watch All Network Flows
```bash
hubble observe
```
Shows all network traffic in real-time with source, destination, verdict (allowed/dropped).

### Watch Specific Pod
```bash
hubble observe --pod my-pod-name
hubble observe --pod my-pod-name --follow
```

### Watch Specific Namespace
```bash
hubble observe --namespace production
hubble observe -n production --follow
```

### Watch Last N Flows
```bash
hubble observe --last 100
hubble observe --last 50 --pod frontend
```

---

## Filtering by Verdict

### Show Only Dropped Traffic (Security Violations)
```bash
hubble observe --verdict DROPPED
hubble observe --verdict DROPPED --follow
```
Critical for security monitoring - shows policy violations.

### Show Only Allowed Traffic
```bash
hubble observe --verdict FORWARDED
```

### Show Policy Audit Logs
```bash
hubble observe --verdict AUDIT
```
When using Cilium policies in audit mode.

---

## Protocol-Specific Queries

### HTTP Traffic Only
```bash
hubble observe --protocol http
hubble observe --protocol http --follow
```

### HTTP with Status Codes
```bash
hubble observe --protocol http --http-status 200
hubble observe --protocol http --http-status 403
hubble observe --protocol http --http-status 500
```

### DNS Queries
```bash
hubble observe --protocol dns
hubble observe --protocol dns --verdict DROPPED
```
Great for debugging service discovery issues.

### TCP Traffic
```bash
hubble observe --protocol tcp --port 443
hubble observe --protocol tcp --port 8080
```

### UDP Traffic
```bash
hubble observe --protocol udp
hubble observe --protocol udp --port 53  # DNS
```

---

## Label-Based Filtering

### Filter by Source Labels
```bash
hubble observe --from-label app=frontend
hubble observe --from-label tier=backend
hubble observe --from-label team=payments
```

### Filter by Destination Labels
```bash
hubble observe --to-label app=database
hubble observe --to-label tier=data
```

### Combine Source and Destination
```bash
hubble observe --from-label app=frontend --to-label app=backend
```

---

## Advanced Queries for Financial Services

### 1. Monitor Payment API Traffic
```bash
# Watch all HTTP calls to payment service
hubble observe \
  --to-label app=payment-api \
  --protocol http \
  --follow

# Filter by HTTP method
hubble observe \
  --to-label app=payment-api \
  --protocol http \
  --http-method POST
```

### 2. Detect Unauthorized Database Access
```bash
# Show who's trying to reach database
hubble observe \
  --to-label tier=database \
  --verdict DROPPED \
  --follow

# Alert on unexpected sources
hubble observe \
  --to-label app=treasury-db \
  --not-from-label app=treasury-api \
  --verdict DROPPED
```

### 3. PCI-DSS Compliance Monitoring
```bash
# Monitor outbound connections from PCI scope
hubble observe \
  --from-label pci-scope=in-scope \
  --to-identity world \
  --follow

# Should be empty! No outbound to internet allowed
```

### 4. Cross-Namespace Communication Audit
```bash
# Detect cross-namespace traffic (potential lateral movement)
hubble observe \
  --from-namespace production \
  --to-namespace staging \
  --follow
```

### 5. API Rate Limiting Detection
```bash
# Monitor for 429 (Too Many Requests) responses
hubble observe \
  --protocol http \
  --http-status 429 \
  --follow
```

---

## Debugging Scenarios

### Scenario 1: Service Can't Reach Another Service
```bash
# Step 1: Check if traffic is being sent
hubble observe --from-pod frontend --to-service backend

# Step 2: Look for drops
hubble observe --from-pod frontend --verdict DROPPED

# Step 3: Check DNS resolution
hubble observe --from-pod frontend --protocol dns

# Step 4: Identify blocking policy
hubble observe --from-pod frontend --verdict DROPPED -o json | jq .drop_reason_desc
```

### Scenario 2: High Latency Investigation
```bash
# Show HTTP response times
hubble observe \
  --protocol http \
  --to-label app=slow-service \
  -o jsonpb | jq .l7.http.latency

# Filter slow requests (requires custom parsing)
hubble observe --protocol http --to-label app=api -o json
```

### Scenario 3: Security Incident Response
```bash
# Find all blocked connections from compromised pod
hubble observe \
  --from-pod suspicious-pod \
  --verdict DROPPED \
  --last 1000

# Identify unusual destinations
hubble observe \
  --from-pod suspicious-pod \
  --to-identity world \
  --last 1000
```

---

## Output Formats

### JSON Output (for automation)
```bash
hubble observe --verdict DROPPED -o json
hubble observe --verdict DROPPED -o jsonpb
```

### Compact Format
```bash
hubble observe --compact
```

### Dict Format (key-value pairs)
```bash
hubble observe -o dict
```

---

## Time-Based Queries

### Since Specific Time
```bash
hubble observe --since 2025-01-12T10:00:00Z
```

### Until Specific Time
```bash
hubble observe --until 2025-01-12T11:00:00Z
```

### Time Range
```bash
hubble observe \
  --since 2025-01-12T10:00:00Z \
  --until 2025-01-12T11:00:00Z \
  --verdict DROPPED
```

---

## Cost Management Use Cases

### 1. Identify Unused Services
```bash
# Services receiving no traffic in last hour
hubble observe --to-label app=unused-service --last 10000

# If empty, consider scaling down or removing
```

### 2. Cross-AZ Traffic Detection (Cost Optimization)
```bash
# Cross-AZ traffic incurs data transfer costs
hubble observe --from-label topology.kubernetes.io/zone=us-east-1a \
  --to-label topology.kubernetes.io/zone=us-east-1b \
  --follow
```

### 3. Egress Traffic Monitoring (NAT Gateway Costs)
```bash
# Outbound internet traffic (most expensive)
hubble observe --to-identity world --follow

# Calculate monthly cost: GB transferred * $0.045/GB
```

### 4. Service Mesh Cost Avoidance Validation
```bash
# Verify L7 policies work without Istio sidecars
hubble observe --protocol http --follow

# Compare:
# - With Cilium: 2% CPU overhead
# - With Istio: 15% CPU + 250MB RAM per pod
```

---

## Prometheus Metrics Integration

### Enable Metrics Export
```bash
# Hubble exports to Prometheus automatically
# Query in Prometheus:
# - hubble_flows_processed_total
# - hubble_drop_total
# - hubble_http_requests_total
# - hubble_http_responses_total
```

### Example Prometheus Queries
```promql
# Request rate by service
rate(hubble_http_requests_total[5m])

# Drop rate
rate(hubble_drop_total[5m])

# HTTP error rate
rate(hubble_http_responses_total{status=~"5.."}[5m])
```

---

## Alerting Examples

### Alert on Policy Violations
```bash
# Script to monitor drops and send alert
hubble observe --verdict DROPPED --follow | \
  while read line; do
    echo "[ALERT] Policy violation: $line"
    # Send to Slack/PagerDuty/etc
  done
```

### Alert on Suspicious Egress
```bash
# Monitor for unexpected internet access
hubble observe --to-identity world --follow | \
  grep -v "expected-destination" | \
  while read line; do
    echo "[SECURITY] Unexpected egress: $line"
  done
```

---

## Performance Tips

### Use --last Instead of --since for Speed
```bash
# Faster
hubble observe --last 100 --verdict DROPPED

# Slower
hubble observe --since 10m --verdict DROPPED
```

### Filter Early in Pipeline
```bash
# Good: filter before observing
hubble observe --verdict DROPPED --pod frontend

# Bad: filter after
hubble observe | grep frontend
```

---

## Hubble UI

### Access Web Interface
```bash
# Port forward in background
cilium hubble ui

# Open browser to http://localhost:12000
```

### UI Features
- Visual service map
- Real-time flow graph
- Interactive filtering
- Export flows as JSON
- Perfect for demos and presentations

---

## Production Best Practices

### 1. Log Retention
```bash
# Configure Hubble to retain flows
cilium hubble enable --relay-buffer-size=10000
```

### 2. Sampling for High Traffic
```bash
# Only log 1 in 100 flows to reduce overhead
# (configure in Cilium ConfigMap)
```

### 3. Export to Long-Term Storage
```bash
# Export flows to S3/CloudWatch for compliance
hubble observe -o json | aws s3 cp - s3://logs/hubble/$(date +%Y%m%d).json
```

---

## Quick Reference Card

```bash
# Real-time monitoring
hubble observe --follow

# Security
hubble observe --verdict DROPPED

# Specific service
hubble observe --to-label app=myservice

# HTTP debugging
hubble observe --protocol http --http-status 500

# DNS issues
hubble observe --protocol dns --verdict DROPPED

# Cross-namespace
hubble observe --from-namespace prod --to-namespace staging

# Cost Management: Egress traffic
hubble observe --to-identity world

# Export for analysis
hubble observe --last 10000 -o json > flows.json
```

---

## Learning Path

1. **Start**: `hubble observe` to see all traffic
2. **Filter**: Add `--pod`, `--namespace`, `--protocol`
3. **Debug**: Use `--verdict DROPPED` to find issues
4. **Optimize**: Monitor with labels for Cost Management insights
5. **Automate**: Export to JSON and integrate with monitoring

---

**Pro Tip**: Keep a terminal with `hubble observe --follow` always running during development. It's like `tcpdump` but human-readable!
