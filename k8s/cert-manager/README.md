# cert-manager (Kubernetes 1.37)

Pinned **v1.21.2** (static upstream manifest, no Helm).

## Install

```bash
kubectl apply -f install.yaml
kubectl -n cert-manager wait --for=condition=Ready pod \
  -l app.kubernetes.io/instance=cert-manager --timeout=300s
kubectl apply -f clusterissuer-selfsigned.yaml
```

Expected: `cert-manager`, `cert-manager-cainjector`, `cert-manager-webhook` all `1/1 Running`. Webhook can take 2–3 min on cold cache; cainjector and controller come up first.

`clusterissuer-selfsigned.yaml` ships a `selfsigned` `ClusterIssuer` so callers don't have to hand-roll one — `spec.selfSigned: {}` issues on-cluster certs without ACME / DNS, usable directly via `issuerRef: { name: selfsigned }` (e.g. for kubelet serving certs, webhook certs, ingress with `cert-manager.io/cluster-issuer: selfsigned`, etc.). Replace with a real CA/ACME issuer for anything that leaves the cluster.

## Verify

```bash
kubectl get clusterissuer selfsigned -o wide   # READY=True
kubectl apply -f smoke-selfsigned.yaml
kubectl get cert -n cert-manager                # selfsigned-smoke Ready
kubectl get secret cm-smoke-test-tls -n cert-manager \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -subject -issuer -dates
```

The smoke cert is a CA (`isCA: true`, `CA:TRUE`), subject == issuer == `CN=cm-smoke-test`.

## Uninstall

```bash
kubectl delete -f smoke-selfsigned.yaml
kubectl delete -f clusterissuer-selfsigned.yaml
kubectl delete -f install.yaml
```

Renewal / DNS-01 / ACME issuers need per-provider configuration beyond the selfsigned one.