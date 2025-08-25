# Homelab Kubernetes Bootstrap

This repository contains the initial bootstrap configuration for my Kubernetes homelab cluster.
It is intended to be applied after the cluster infrastructure is provisioned via Infrastructure as Code (IaC).

---

## Pre-requisites

* Kubernetes cluster deployed via the IaC.
* `kubectl` context set to the new cluster.
* `kustomize` available (or use `kubectl apply -k`).

---

## Components

### **1. ArgoCD**

* **Purpose:** GitOps-based continuous delivery for Kubernetes.
* **Manifests:** Located in `resources/argocd/`

  * `namespace.yaml` creates the `argocd` namespace.
  * `install.yaml` installs the ArgoCD components.
  * `ingress.yaml` exposes the ArgoCD UI.

### **2. MetalLB**

* **Purpose:** Load balancer implementation for bare-metal Kubernetes clusters.
* **Manifests:** Located in `resources/metallb/`

  * `install.yaml` installs the MetalLB controller and speaker.
  * `ip-pool.yaml` configures the pool of IP addresses available for LoadBalancer services.

### **3. Ingress-NGINX**

* **Purpose:** HTTP ingress controller for routing traffic into services.
* **Patches:** Located in `patches/`

  * `ingress-nginx-ingress-class.yaml` customizes the `IngressClass` resource.
  * `ingress-nginx-deployment.yaml` modifies the controller deployment (e.g., args, resources).

---

## Installation

**1. Apply the configuration**

```bash
kubectl apply -k .
```

**2. Verify**

```bash
kubectl get pods -n argocd
kubectl get pods -n metallb-system
kubectl get pods -n ingress-nginx
```
