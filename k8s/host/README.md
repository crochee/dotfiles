# Host Docker daemon config

Archive of the host's `/etc/docker/daemon.json` — byte-identical (verified with `sha256sum`).

Mirrors here are the same set baked into `../kind-cluster-config.yaml` `containerdConfigPatches.registry.mirrors`, so host-side and in-cluster pulls resolve through the same endpoints.

## Why an archive, not managed config

The file is host-state (different per host) and editing it requires a dockerd restart. Mistakes break all containers on the host. The repo copy is a reference + bootstrap:

```bash
sudo cp k8s/host/daemon.json /etc/docker/daemon.json && sudo systemctl restart docker
```

## Re-syncing

```bash
sudo cp /etc/docker/daemon.json ~/.dotfiles/k8s/host/daemon.json
diff /etc/docker/daemon.json ~/.dotfiles/k8s/host/daemon.json && echo OK
```