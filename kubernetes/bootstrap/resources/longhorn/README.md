# Longhorn Installation

This directory contains the manifests and kustomization for deploying [Longhorn](https://longhorn.io/) on your Kubernetes cluster.

## Files

- `namespace.yaml`: Namespace for Longhorn.
- `install.yaml`: Upstream Longhorn installation manifest.
- `ingress.yaml`: Ingress for Longhorn UI.
- `kustomization.yaml`: Kustomize file to manage resources.

## Installation

To install Longhorn, run:

```sh
kubectl apply -k kubernetes/bootstrap/resources/longhorn/
```

Or, if you prefer to apply the manifests directly:

```sh
kubectl apply -f kubernetes/bootstrap/resources/longhorn/namespace.yaml
kubectl apply -f kubernetes/bootstrap/resources/longhorn/install.yaml
kubectl apply -f kubernetes/bootstrap/resources/longhorn/ingress.yaml
```

## Talos Disk Mounting for Longhorn

If your worker node has a disk (e.g., `/dev/sdb1` with XFS) for Longhorn, but it is not mounted, follow these steps:

1. **Patch Talos machine config to mount the disk:**
   - Mount `/dev/sdb1` at `/var/lib/longhorn` with XFS.

2. **Add kubelet.extraMounts:**
   - Ensure kubelet mounts `/var/lib/longhorn` into pods.

3. **Add util-linux-tools extension:**
   - Add `siderolabs/util-linux-tools` to Talos extensions.

4. **Allow privileged pods in longhorn-system:**
   - Patch the namespace for privileged workloads.

5. **Re-apply Longhorn manifests and restart driver-deployer.**

6. **Verify Longhorn UI and storage functionality.**
