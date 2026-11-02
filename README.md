# dotfiles

Managed by chezmoi. Bootstrap: `bash install/install.sh`.

- Tool versions: `home/dot_config/mise/config.toml.tmpl` (single source).
- Bootstrap / dialect reset / `OMP_CONFIG_FORCE=1` / `chezmoi init --apply` flow lives in `install/install.sh`.
- Docker daemon: `bin/docker-daemon {setup|start|stop|restart|status|revert} [--dry-run]` — Linux=systemd (own unit), macOS=colima (mise-managed). Daemons are owned by `aqua-docker-cli` (mise).
- Local overrides + secrets: `home/.chezmoidata/local.yaml` (gitignored, 0600). Don't put git identity in `~/.config/chezmoi/chezmoi.toml [data]` — that source overrides `local.yaml`.
- Maintenance: `da` (diff-then-apply), `daf` (force apply), `./install/cleanup.sh --only={cache|docker|dups}`.
- Wox Custom Commands catalog: `home/dot_wox/wox-user/shortcuts.json` (sachadvr/Wox.Custom.Commands.Plugin). Mirror of Wox store runs on WSL host (see `home/.chezmoiscripts/run_after_sync-windows.sh.tmpl`).
- OpenSpec schema `superpowers-bridge`：源码 `home/dot_local/share/openspec/schemas/superpowers-bridge/`，部署到 `~/.local/share/openspec/schemas/superpowers-bridge/`（用户级，所有项目可用）。内容为简体中文；引用的 superpowers 系 skill 一律去前缀，缺失即中止。CLI 由 mise 纳管（`npm:@fission-ai/openspec`）。接入见 `docs/OPENSPEC-BRIDGE.md`：每个项目只写一个 `openspec/config.yaml`，不跑 `openspec init`，skill 全部由用户级 `~/.agents/skills/` 提供。一条命令代劳：`openspec-bridge {skills|init|check}`（源 `home/dot_local/bin/`，部署到 `~/.local/bin/`）。
- Agent Skills：源码 `home/dot_agents/skills/`，部署到 `~/.agents/skills/`（omp 原生加载的通用 skill 目录；Claude Code 只读 `~/.claude/skills/`，故不再同步）。本仓自建 13 个：`frontend-design`（v3,UI/UX + 实现 + 审计）、`architecture-design`、`api-design`、`agent-engineering`、`de-ai-tone`、`deep-research`（证据台账 + 反证检索 + 带引用综合，纯标准库脚本）、`golang-dev`、`k8s-operator`、`legal-risk-auditor`、`python-dev`、`repo-wiki`、`rust-dev`、`technical-writing`；13 个自建技能都带 `evals/trigger_queries.json`（24 条查询，正例 12 / 反例 12，各 3 条 holdout；`deep-research` 沿用旧集 26 条，13/13），用 `python3 bin/skill-trigger-eval --skills all --runs 3 --jobs 8 --max-time 120 --session-timeout 150` 实测：正例看 skill 是否被加载（consult，通过线 0.8），反例看工作流是否接管（workflow ≤0.2）。实测结果 `evals/*_results.json` 不入库；写作标准见 `docs/AGENT-SKILLS.md` §7。
- 第三方/插件技能（mattpocock、superpowers）的安装、版本更新与回滚：`docs/AGENT-SKILLS.md`。
- Layout / keymap / housekeeping rationale: `docs/KEYMAP.md`, `home/dot_config/nvim/README.md`, `note.txt`.

## Hosts

- WSL ↔ Windows: Windows host owns wezterm, Wox; everything else lives in WSL under this repo (`~/.dotfiles`). WSL↔Windows sync hooks mirror wezterm config, `shortcuts.json` (overwrite), and `settings/wox.json` (jq deep-merge) to the Windows side.
- Native Linux: wezterm + Wox (Linux build) run directly; no WSL↔Windows step.
- macOS: wezterm + Wox (mac build) run directly; docker via colima (mise-managed).

## rg 优先

User-facing 搜索 / 文件列举一律用 rg；例外见 `note.txt`。 <!-- scan: ignore E3 标题给的是主题，首行给的是适用范围和例外 -->