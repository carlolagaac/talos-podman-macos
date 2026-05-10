#!/usr/bin/env bash
set -euo pipefail

# Create or destroy a Talos Kubernetes cluster in Podman
# Requires: brew install talosctl kubectl
# Usage: ./02-create-talos-cluster.sh [create|destroy]

ACTION="${1:-create}"
CLUSTER_NAME="${CLUSTER_NAME:-dev}"
WORKERS="${WORKERS:-1}"
CPUS="${TALOS_CPUS:-2.0}"
MEMORY="${TALOS_MEMORY:-2048}"
TALOS_VERSION="${TALOS_VERSION:-v1.13.0}"
K8S_VERSION="${K8S_VERSION:-1.36.0}"

if [ "$ACTION" = "destroy" ]; then
  echo "==> Destroying Talos cluster '$CLUSTER_NAME'..."
  talosctl cluster destroy --name "$CLUSTER_NAME"
  kubectl config delete-context "admin@${CLUSTER_NAME}" 2>/dev/null || true
  kubectl config delete-cluster "$CLUSTER_NAME" 2>/dev/null || true
  echo "Done."
  exit 0
fi

echo "==> Ensuring br_netfilter is loaded in Podman VM..."
podman machine ssh -- sudo modprobe br_netfilter

echo "==> Creating Talos cluster"
echo "    Name: $CLUSTER_NAME"
echo "    Workers: $WORKERS | CPUs: $CPUS | Memory: ${MEMORY}MB"
echo "    Talos: $TALOS_VERSION | K8s: $K8S_VERSION"

talosctl cluster create docker \
  --name "$CLUSTER_NAME" \
  --workers "$WORKERS" \
  --cpus-controlplanes "$CPUS" \
  --cpus-workers "$CPUS" \
  --memory-controlplanes "${MEMORY}MB" \
  --memory-workers "${MEMORY}MB" \
  --image "ghcr.io/siderolabs/talos:${TALOS_VERSION}" \
  --kubernetes-version "$K8S_VERSION"

echo ""
echo "==> Fetching kubeconfig..."
NODE_IP="127.0.0.1"
talosctl --nodes "$NODE_IP" kubeconfig --force

# Fix server URL — talosctl writes the internal container IP, use the host-mapped port
API_PORT=$(podman port "${CLUSTER_NAME}-controlplane-1" 6443 2>/dev/null | head -1 | cut -d: -f2)
if [ -n "$API_PORT" ]; then
  kubectl config set-cluster "$CLUSTER_NAME" --server="https://127.0.0.1:${API_PORT}"
fi

kubectl config use-context "admin@${CLUSTER_NAME}"

echo ""
echo "==> Cluster ready!"
kubectl get nodes
