#!/bin/bash
set -e

CLUSTER_NAME="cilium-lab"

echo "🔍 Verifying Cilium installation..."

# Switch to correct context
kubectl config use-context $CLUSTER_NAME

# Check cluster status
echo ""
echo "📊 Cluster Status:"
kubectl get nodes

# Check Cilium pods
echo ""
echo "🐝 Cilium Pods:"
kubectl get pods -n kube-system -l k8s-app=cilium

# Cilium connectivity test
echo ""
echo "🧪 Running Cilium connectivity test (this takes 2-3 minutes)..."
cilium connectivity test --test-concurrency=1

echo ""
echo "✅ Verification complete!"
echo ""
echo "💡 Useful commands:"
echo "  - cilium status"
echo "  - cilium connectivity test"
echo "  - kubectl -n kube-system exec ds/cilium -- cilium-dbg status"
echo ""
