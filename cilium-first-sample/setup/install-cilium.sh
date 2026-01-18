#!/bin/bash
set -e

CLUSTER_NAME="cilium-lab"

echo "🐝 Installing Cilium CNI..."

# Check if Cilium CLI is installed
if ! command -v cilium &> /dev/null; then
    echo "📥 Installing Cilium CLI..."
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    CLI_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
    rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
fi

# Switch to correct cluster context
kubectl config use-context $CLUSTER_NAME

# Install Cilium
echo "📦 Installing Cilium (this takes 1-2 minutes)..."
cilium install \
    --version 1.16.5 \
    --wait

# Wait for Cilium to be ready
echo "⏳ Waiting for Cilium to be ready..."
cilium status --wait

echo "✅ Cilium installed successfully!"

# Show status
cilium status

echo ""
echo "📋 Next steps:"
echo "  1. Run: ./verify.sh"
echo "  2. Deploy demo apps in cilium-policies/"
echo ""
