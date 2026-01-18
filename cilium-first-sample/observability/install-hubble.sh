#!/bin/bash
set -e

CLUSTER_NAME="cilium-lab"

echo "👁️  Installing Hubble for network observability..."

# Switch to correct cluster context
kubectl config use-context $CLUSTER_NAME

# Enable Hubble in Cilium
echo "📦 Enabling Hubble..."
cilium hubble enable --ui

# Wait for Hubble to be ready
echo "⏳ Waiting for Hubble to be ready..."
cilium status --wait

# Check Hubble status
echo ""
echo "🔍 Hubble Status:"
cilium hubble port-forward&
PORTFORWARD_PID=$!

sleep 5

# Install Hubble CLI if not present
if ! command -v hubble &> /dev/null; then
    echo "📥 Installing Hubble CLI..."
    HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
    HUBBLE_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
    curl -L --fail --remote-name-all \
        https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
    rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
fi

# Test Hubble CLI
echo ""
echo "🧪 Testing Hubble CLI connection..."
hubble status

echo ""
echo "✅ Hubble installed successfully!"
echo ""
echo "📋 Access Hubble UI:"
echo "  Run in separate terminal: cilium hubble ui"
echo "  Then open: http://localhost:12000"
echo ""
echo "💡 Useful Hubble commands:"
echo "  - hubble observe                    # Watch all flows"
echo "  - hubble observe --pod <pod-name>   # Watch specific pod"
echo "  - hubble observe --verdict DROPPED  # Show blocked traffic"
echo "  - hubble observe --protocol http    # Show HTTP traffic"
echo ""

# Deploy demo workloads for testing
echo "🚀 Deploying demo workloads for observability testing..."

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-a
  labels:
    app: test-a
spec:
  containers:
  - name: curl
    image: curlimages/curl:latest
    command: ["sleep", "3600"]

---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-b
  labels:
    app: test-b
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: test-service-b
spec:
  selector:
    app: test-b
  ports:
  - port: 80
    targetPort: 80
EOF

echo ""
echo "⏳ Waiting for demo pods to be ready..."
kubectl wait --for=condition=ready pod/test-pod-a pod/test-pod-b --timeout=60s

echo ""
echo "✅ Demo workloads ready!"
echo ""
echo "🧪 Try these tests:"
echo "  1. Generate traffic:"
echo "     kubectl exec test-pod-a -- curl http://test-service-b"
echo ""
echo "  2. Watch in Hubble:"
echo "     hubble observe --pod test-pod-a"
echo ""
echo "  3. Apply network policy and observe blocks:"
echo "     kubectl apply -f ../cilium-policies/l3-deny-all.yaml"
echo "     hubble observe --verdict DROPPED"
echo ""

# Stop port forward
kill $PORTFORWARD_PID 2>/dev/null || true
