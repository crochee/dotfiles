# Kind cluster (6 nodes, 1.37)

Kindnet CNI, kube-proxy `nftables`. cert-manager is deployed after — see `k8s/cert-manager/README.md`.

## Prerequisites

- Docker installed; host registry mirrors at `/etc/docker/daemon.json` (archived in `k8s/host/daemon.json`).
- `kind`, `kubectl` (mise-managed).
- `$DOTFILES_DIR` is this checkout; `$DOTFILES_DIR/bin` is on PATH.

## Containerd registry mirrors

`kind-cluster-config.yaml` bakes the same mirrors as `k8s/host/daemon.json` into each node via `containerdConfigPatches`, so both host and in-cluster image pulls hit the same endpoints. No per-node `certs.d/` setup or `docker exec` after cluster creation.

## Create

```bash
kind create cluster --config=$DOTFILES_DIR/k8s/kind-cluster-config.yaml

kubectl get pods -n kube-system -l app=kindnet
kubectl -n kube-system get cm kube-proxy -o jsonpath='{.data.config\.conf}' | grep ^mode:    # expect: mode: nftables
```

Node IPs come from the docker network subnet (default `172.18.0.0/16`).

## cert-manager

```bash
kubectl apply -f $DOTFILES_DIR/k8s/cert-manager/install.yaml
kubectl -n cert-manager wait --for=condition=Ready pod -l app.kubernetes.io/instance=cert-manager --timeout=300s
kubectl apply -f $DOTFILES_DIR/k8s/cert-manager/clusterissuer-selfsigned.yaml
kubectl apply -f $DOTFILES_DIR/k8s/cert-manager/smoke-selfsigned.yaml
kubectl get clusterissuer selfsigned -o wide   # READY=True
kubectl get cert -n cert-manager               # selfsigned-smoke Ready
```

## Smoke test

```bash
kubectl create deployment nginx --image=nginx:1.27-alpine
kubectl expose deployment nginx --port=80 --target-port=80
kubectl get svc nginx    # ClusterIP only (no LB in kind)
kubectl port-forward svc/nginx 8080:80    # from the host
```

## Troubleshooting

- **No pod network**: confirm `kubectl get pods -n kube-system -l app=kindnet`.
- **`short read: ... 301 bytes`**: mirror returned an HTTP redirect. Pre-pull from `docker.io` direct (slow on flaky networks).