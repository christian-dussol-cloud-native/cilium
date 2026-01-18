#!/bin/bash
set -e

# Configuration
CLUSTER_NAME="cilium-lab"
DRIVER="docker"  # Change to 'virtualbox' or 'podman' if needed
KUBERNETES_VERSION="1.30.0"
CPUS="4"
MEMORY="8192"
NODES="1"

echo "🚀 Creating Minikube cluster for Cilium learning..."

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube not found. Install from: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Check if cluster already exists
if minikube status -p $CLUSTER_NAME &> /dev/null; then
    echo "⚠️  Cluster '$CLUSTER_NAME' already exists."
    read -p "Delete and recreate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing cluster..."
        minikube delete -p $CLUSTER_NAME
    else
        echo "✅ Using existing cluster."
        exit 0
    fi
fi

# Create cluster WITHOUT default CNI (we'll install Cilium)
echo "📦 Creating Minikube cluster (this may take 2-3 minutes)..."
minikube start \
    --profile=$CLUSTER_NAME \
    --driver=$DRIVER \
    --kubernetes-version=$KUBERNETES_VERSION \
    --cpus=$CPUS \
    --memory=$MEMORY \
    --nodes=$NODES \
    --network-plugin=cni \
    --cni=false

# Verify cluster
echo "✅ Cluster created successfully!"
kubectl get nodes

echo ""
echo "📋 Next steps:"
echo "  1. Run: ./install-cilium.sh"
echo "  2. Run: ./verify.sh"
echo ""
echo "💡 Access dashboard: minikube dashboard -p $CLUSTER_NAME"
