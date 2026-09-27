# dotfiles

chezmoi-managed dotfiles. Bootstrap: `bash install/install.sh`.

- Tool versions: `home/dot_config/mise/config.toml.tmpl` (single source).
- Bootstrap / dialect reset / `OMP_CONFIG_FORCE=1` / `chezmoi init --apply` flow lives in `install/install.sh`.
- Docker daemon: `bin/docker-daemon {setup|start|stop|restart|status|revert} [--dry-run]` — Linux=systemd (own unit), macOS=colima (mise-managed). Daemons are owned by `aqua-docker-cli` (mise).
- Local overrides + secrets: `home/.chezmoidata/local.yaml` (gitignored, 0600). Don't put git identity in `~/.config/chezmoi/chezmoi.toml [data]` — that source overrides `local.yaml`.
- Maintenance: `da` (diff-then-apply), `daf` (force apply), `./install/cleanup.sh --only={cache|docker|dups}`.
- Wox + quiver catalog: `home/dot_wox/wox-user/ShellCommands.json`. Mirror of Wox store runs on WSL host (see `home/.chezmoiscripts/run_after_apply_install-quiver-stub.sh.tmpl`).
- Layout / keymap / housekeeping rationale: `docs/KEYMAP.md`, `home/dot_config/nvim/README.md`, `note.txt`.

## Hosts

- **WSL ↔ Windows**: Windows host owns wezterm, Wox, quiver; everything else lives in WSL under this repo (`~/.dotfiles`). WSL↔Windows sync hooks mirror wezterm config, `ShellCommands.json` (overwrite), and `settings/wox.json` (jq deep-merge) to the Windows side.
- **Native Linux**: wezterm + Wox (Linux build) + quiver run directly; no WSL↔Windows step.
- **macOS**: wezterm + Wox (mac build) + quiver run directly; docker via colima (mise-managed).

## rg 优先

User-facing 搜索 / 文件列举一律用 rg; 例外见 `note.txt`.