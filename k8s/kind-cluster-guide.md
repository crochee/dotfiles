# Kind cluster setup

Cluster uses kind's default CNI (kindnet). Volcano scheduler + MetalLB LoadBalancer.

## Prerequisites

- Docker installed. Host-level registry mirrors live in `/etc/docker/daemon.json` — hand-managed, not in this repo (see `docker info` for what is in effect).
- Kind, kubectl installed (mise-managed in this repo).
- `$DOTFILES_DIR` = this dotfiles checkout (`$DOTFILES_DIR/bin` is on PATH).

## Registry mirrors

Node-side containerd mirrors live in `k8s/certs.d/` (hosts.toml per registry). `kind-cluster-config.yaml` only sets `config_path` — containerd 2.x node images (kind v0.27+) ship that default; the patch exists for older images. The hosts.toml files are copied into the nodes after cluster creation (kind `extraMounts` needs an absolute host path, which would break on another machine). `kind get nodes` defaults to the cluster named `kind` — pass `--name` for others (e.g. the `cim` cluster):

```bash
for n in $(kind get nodes --name "${KIND_CLUSTER_NAME:-kind}"); do
    docker exec "$n" mkdir -p /etc/containerd/certs.d
    docker cp "$DOTFILES_DIR/k8s/certs.d/." "$n:/etc/containerd/certs.d/"
    docker exec "$n" systemctl restart containerd
done
```

Run this after every `kind create cluster` — workload image pulls go through these mirrors (kind pre-loads its bootstrap images, so creation itself does not need the step).

## Creating the Kind cluster

```bash
kind create cluster --config=$DOTFILES_DIR/k8s/kind-cluster-config.yaml
```

`kind-cluster-config.yaml` keeps kind's built-in CNI (`disableDefaultCNI: false`), so the cluster has working pod networking the moment it is created. Verify with:

```bash
kubectl get pods -n kube-system -l app=kindnet
```

### Switching to Calico

Only if you actually need Calico's NetworkPolicy/dual-stack. A cluster cannot run two CNIs, so the config must disable the built-in one first:

```yaml
networking:
  disableDefaultCNI: true
  podSubnet: "192.168.0.0/16"
```

then recreate the cluster and apply the manifest:

```bash
kind delete cluster && kind create cluster --config=$DOTFILES_DIR/k8s/kind-cluster-config.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/calico.yaml
kubectl get pods -n calico-system
```

## Volcano scheduler

```bash
kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/master/installer/volcano-development.yaml
kubectl get pods -n volcano-system
```

Use it by setting `schedulerName: volcano` on a pod spec.

## MetalLB LoadBalancer

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
```

Get the Kind network subnet, then create an IP pool and L2 advertisement:

```bash
docker network inspect kind | rg Subnet
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.18.255.200-172.18.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
```

## Smoke test

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get svc nginx   # EXTERNAL-IP should appear
```

## Troubleshooting

- **Pods have no network / no CNI**: confirm `kubectl get pods -n kube-system -l app=kindnet`. If you switched to Calico, the built-in CNI must be disabled in the config *before* creating the cluster.
- **Volcano scheduler not being assigned**: ensure `schedulerName: volcano` is on the pod spec; check `kubectl get pods -n volcano-system`.
- **MetalLB not assigning IPs**: pool range must be inside the Kind network CIDR; check `kubectl logs -n metallb-system <controller-pod>`.
- **LoadBalancer service pending**: wait a few minutes for MetalLB to assign an IP.