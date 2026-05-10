#!/usr/bin/env bash
set -euo pipefail

# Configure Podman machine for Talos Kubernetes
# Requires: brew install podman

MACHINE_NAME="${MACHINE_NAME:-podman-machine-default}"
CPUS="${PODMAN_CPUS:-4}"
MEMORY="${PODMAN_MEMORY:-6144}"
DISK_SIZE="${PODMAN_DISK:-100}"

echo "==> Checking for existing Podman machine..."
if podman machine inspect "$MACHINE_NAME" &>/dev/null; then
  echo "Machine '$MACHINE_NAME' already exists."
  STATE=$(podman machine inspect "$MACHINE_NAME" --format '{{.State}}')
  if [ "$STATE" != "running" ]; then
    echo "==> Starting machine..."
    podman machine start "$MACHINE_NAME"
  else
    echo "Machine is already running."
  fi
else
  echo "==> Initializing Podman machine: $MACHINE_NAME"
  echo "    CPUs: $CPUS | Memory: ${MEMORY}MB | Disk: ${DISK_SIZE}GB"
  podman machine init "$MACHINE_NAME" \
    --cpus "$CPUS" \
    --memory "$MEMORY" \
    --disk-size "$DISK_SIZE" \
    --rootful

  echo "==> Starting machine..."
  podman machine start "$MACHINE_NAME"
fi

echo "==> Loading required kernel modules in Podman VM..."
podman machine ssh -- sudo modprobe br_netfilter
podman machine ssh -- sudo sh -c 'echo br_netfilter > /etc/modules-load.d/br_netfilter.conf'

echo "==> Verifying Podman is working..."
podman info --format '{{.Host.Os}} | CPUs: {{.Host.CPUs}} | Memory: {{.Host.MemTotal}}'

echo ""
echo "Done. Podman machine '$MACHINE_NAME' is ready for Talos."
