#!/bin/bash
set -e

CLUSTER_NAME="cilium-lab"

echo "Cleaning up Minikube cluster..."

read -p "Delete cluster '$CLUSTER_NAME'? This cannot be undone. (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    minikube delete -p $CLUSTER_NAME
    echo "✅ Cluster deleted successfully."
else
    echo "❌ Cleanup cancelled."
fi
