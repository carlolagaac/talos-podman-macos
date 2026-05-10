# Talos Kubernetes on Podman (macOS)

Scripts to run a [Talos Linux](https://www.talos.dev/) Kubernetes cluster locally on macOS using Podman as the container runtime.

## Prerequisites

```bash
brew install talosctl kubectl podman
```

## Quick Start

```bash
# 1. Configure Podman machine (first time)
./01-configure-podman.sh

# 2. Create cluster
./02-create-talos-cluster.sh create

# 3. Destroy cluster
./02-create-talos-cluster.sh destroy
```

## Scripts

| Script | Purpose |
|--------|---------|
| `01-configure-podman.sh` | Initializes a rootful Podman machine (4 CPUs, 6 GB RAM) and loads `br_netfilter` |
| `02-create-talos-cluster.sh` | Creates or destroys a Talos cluster, fixes kubeconfig server URL automatically |

## Configuration

Override defaults via environment variables:

```bash
# Podman machine
PODMAN_CPUS=4  PODMAN_MEMORY=6144  PODMAN_DISK=100

# Talos cluster
CLUSTER_NAME=dev  WORKERS=1  TALOS_CPUS=2.0  TALOS_MEMORY=2048
TALOS_VERSION=v1.13.0  K8S_VERSION=1.36.0
```

## Troubleshooting

See [talos-cluster-setup.md](talos-cluster-setup.md) for detailed notes on issues encountered (Flannel CrashLoopBackOff, kubeconfig IP mismatch, etc.) and their fixes.

## License

[MIT](LICENSE)
