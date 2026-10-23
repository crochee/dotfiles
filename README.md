# dotfiles

chezmoi-managed dotfiles. Bootstrap: `bash install/install.sh`.

- Tool versions: `home/dot_config/mise/config.toml.tmpl` (single source).
- Bootstrap / dialect reset / `OMP_CONFIG_FORCE=1` / `chezmoi init --apply` flow lives in `install/install.sh`.
- Docker daemon: `bin/docker-daemon {setup|start|stop|restart|status|revert} [--dry-run]` — Linux=systemd (own unit), macOS=colima (mise-managed). Daemons are owned by `aqua-docker-cli` (mise).
- Local overrides + secrets: `home/.chezmoidata/local.yaml` (gitignored, 0600). Don't put git identity in `~/.config/chezmoi/chezmoi.toml [data]` — that source overrides `local.yaml`.
- Maintenance: `da` (diff-then-apply), `daf` (force apply), `./install/cleanup.sh --only={cache|docker|dups}`.
- Wox Custom Commands catalog: `home/dot_wox/wox-user/shortcuts.json` (sachadvr/Wox.Custom.Commands.Plugin). Mirror of Wox store runs on WSL host (see `home/.chezmoiscripts/run_after_sync-windows.sh.tmpl`).
- OpenSpec schema `superpowers-bridge`:源码 `home/dot_local/share/openspec/schemas/superpowers-bridge/`,部署到 `~/.local/share/openspec/schemas/superpowers-bridge/`(用户级,所有项目可用)。内容为简体中文;引用的 superpowers 系 skill 一律去前缀,缺失即中止。CLI 由 mise 纳管(`npm:@fission-ai/openspec`)。接入见 `docs/OPENSPEC-BRIDGE.md`:每个项目只写一个 `openspec/config.yaml`,不跑 `openspec init`,skill 全部由用户级 `~/.agents/skills/` 提供。一条命令代劳:`openspec-bridge {skills|init|check}`(源 `home/dot_local/bin/` → `~/.local/bin/`)。
- Agent Skills: 源码 `home/dot_agents/skills/`,部署到 `~/.agents/skills/`(omp 原生加载的通用 skill 目录;Claude Code 只读 `~/.claude/skills/`,故不再同步)。本仓自建 12 个:`frontend-design`(v3,UI/UX + 实现 + 审计)、`architecture-design`、`api-design`、`agent-engineering`、`de-ai-tone`、`golang-dev`、`k8s-operator`、`legal-risk-auditor`、`python-dev`、`repo-wiki`、`rust-dev`、`technical-writing`;触发召回、with/without 对照与真实任务验收的证据在 `staging/evals/`(不部署)。
- 第三方/插件技能（mattpocock、superpowers）的安装、版本更新与回滚: `docs/AGENT-SKILLS.md`。
- Layout / keymap / housekeeping rationale: `docs/KEYMAP.md`, `home/dot_config/nvim/README.md`, `note.txt`.

## Hosts

- **WSL ↔ Windows**: Windows host owns wezterm, Wox; everything else lives in WSL under this repo (`~/.dotfiles`). WSL↔Windows sync hooks mirror wezterm config, `shortcuts.json` (overwrite), and `settings/wox.json` (jq deep-merge) to the Windows side.
- **Native Linux**: wezterm + Wox (Linux build) run directly; no WSL↔Windows step.
- **macOS**: wezterm + Wox (mac build) run directly; docker via colima (mise-managed).

## rg 优先

User-facing 搜索 / 文件列举一律用 rg; 例外见 `note.txt`.