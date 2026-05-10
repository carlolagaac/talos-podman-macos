# Talos Kubernetes Cluster on Podman (macOS)

## Prerequisites

- `brew install talosctl kubectl podman`
- Podman machine: rootful, ≥4 CPUs, ≥6GB RAM

## Scripts

| Script | Purpose |
|--------|---------|
| `01-configure-podman.sh` | Initializes/starts Podman machine, loads `br_netfilter` kernel module |
| `02-create-talos-cluster.sh` | Creates or destroys a Talos cluster (ensures `br_netfilter` before create) |

### Usage

```bash
# 1. Configure Podman (first time or after reinstall)
./01-configure-podman.sh

# 2. Create cluster
./02-create-talos-cluster.sh create

# 3. Destroy cluster
./02-create-talos-cluster.sh destroy
```

### Variables

```bash
# 01-configure-podman.sh
MACHINE_NAME=podman-machine-default  PODMAN_CPUS=4  PODMAN_MEMORY=6144  PODMAN_DISK=100

# 02-create-talos-cluster.sh
CLUSTER_NAME=dev  WORKERS=1  TALOS_CPUS=2.0  TALOS_MEMORY=2048  TALOS_VERSION=v1.13.0  K8S_VERSION=1.36.0
```

## Issues Encountered & Fixes

### 1. `~/.kube/config` owned by root

```bash
sudo chown $(whoami):staff ~/.kube/config
```

### 2. Kubeconfig points to unreachable internal IP

`talosctl kubeconfig` writes the container-internal IP (e.g. `10.5.0.2:6443`). The create script auto-fixes this by looking up the host-mapped port:

```bash
API_PORT=$(podman port ${CLUSTER_NAME}-controlplane-1 6443 | head -1 | cut -d: -f2)
kubectl config set-cluster $CLUSTER_NAME --server="https://127.0.0.1:${API_PORT}"
```

### 3. Flannel CrashLoopBackOff / CoreDNS stuck in ContainerCreating

**Symptom:** Flannel logs show:
```
Failed to check br_netfilter: stat /proc/sys/net/bridge/bridge-nf-call-iptables: no such file or directory
```

**Cause:** Talos containers share the Podman VM kernel. `br_netfilter` must be loaded in the VM, not inside containers.

**Fix (automated in both scripts):**
```bash
podman machine ssh -- sudo modprobe br_netfilter
```

Persisted across reboots via:
```bash
podman machine ssh -- sudo sh -c 'echo br_netfilter > /etc/modules-load.d/br_netfilter.conf'
```

## Useful Commands

```bash
# Cluster health
talosctl --nodes 127.0.0.1 service

# Kubernetes access
kubectl get nodes
kubectl get pods -n kube-system

# Destroy cluster
./02-create-talos-cluster.sh destroy
```

## How It Works

Talos runs as containers in Podman via the Docker-compatible API. The `talosctl cluster create docker` command:

1. Generates PKI and machine configs
2. Creates a Podman network (bridge, default subnet `10.5.0.0/24`)
3. Launches control plane and worker containers from `ghcr.io/siderolabs/talos:<version>`
4. Bootstraps etcd and the Kubernetes control plane
5. Deploys Flannel CNI, kube-proxy, and CoreDNS

The host accesses the API server via port-forwarded ports on `127.0.0.1`.
