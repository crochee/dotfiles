# dotfiles

Managed by chezmoi. Bootstrap: `bash install/install.sh`.

- Tool versions: `home/dot_config/mise/config.toml.tmpl` (single source).
- Bootstrap / dialect reset / `OMP_CONFIG_FORCE=1` / `chezmoi init --apply` flow lives in `install/install.sh`.
- Docker daemon: `bin/docker-daemon {setup|start|stop|restart|status|revert} [--dry-run]` — Linux=systemd (own unit), macOS=colima (mise-managed). Daemons are owned by `aqua-docker-cli` (mise).
- Local overrides + secrets: `home/.chezmoidata/local.yaml` (gitignored, 0600). Don't put git identity in `~/.config/chezmoi/chezmoi.toml [data]` — that source overrides `local.yaml`.
- Maintenance: `da` (diff-then-apply), `daf` (force apply), `./install/cleanup.sh --only={cache|docker|dups}`.
- Wox Custom Commands catalog: `home/dot_wox/wox-user/shortcuts.json` (sachadvr/Wox.Custom.Commands.Plugin). Mirror of Wox store runs on WSL host (see `home/.chezmoiscripts/run_after_sync-windows.sh.tmpl`).
- Agent Skills：源码 `home/dot_agents/skills/`，部署到 `~/.agents/skills/`（omp 原生加载的通用 skill 目录；Claude Code 只读 `~/.claude/skills/`，故不再同步）。本仓自建 13 个：`frontend-design`（v3,UI/UX + 实现 + 审计）、`architecture-design`、`api-design`、`agent-engineering`、`de-ai-tone`、`deep-research`（证据台账 + 反证检索 + 带引用综合，纯标准库脚本）、`golang-dev`、`k8s-operator`、`legal-risk-auditor`、`python-dev`、`repo-wiki`、`rust-dev`、`technical-writing`；13 个自建技能都带 `evals/trigger_queries.json`（24 条查询，正例 12 / 反例 12，各 3 条 holdout；`deep-research` 沿用旧集 26 条，13/13），用 `python3 bin/skill-trigger-eval --skills all --runs 3 --jobs 8 --max-time 120 --session-timeout 150` 实测：正例看 skill 是否被加载（consult，通过线 0.8），反例看工作流是否接管（workflow ≤0.2）。实测结果 `evals/*_results.json` 不入库；写作标准见 `docs/AGENT-SKILLS.md` §7。
- 上游技能（mattpocock）：27 个（工程级 20 + 生产级 7），用 `npx skills` 装到 `~/.agents/skills/`，安装/更新/回滚见 `docs/AGENT-SKILLS.md`。
- 全局调用约定：源码 `home/dot_agents/AGENTS.md`，部署到 `~/.agents/AGENTS.md`（omp 的 Agent Dirs provider 在 user 级加载，每个项目每个会话都读到）：技能怎么调、流程先后、相似技能分工。
- 智能体（agents）：源码 `home/dot_agents/agents/`，部署到 `~/.agents/agents/`（**4 个，跨 harness 通用**）。frontmatter 只保留 `name` + `description` 两个通用键：**不写 `tools`**（各 harness 工具名方言不同——omp 是小写内建名 `read`/`web_search`，Claude Code 是大写 `Read`/`WebSearch`，pi 是另一套；省略时各 harness 套用自己的默认工具集），也不写 `spawns` / `model` / `thinking` / `output`（omp 私有）。正文不出现任何 harness 专有的工具名与机制（无 `yield`、无 `@slow`、无 omp 输出 schema）。
  - 4 个角色：`explore`（只读定位，按 quick/medium/very thorough 三档，回报 `path:line`）/ `plan`（只读规划，分步计划 + 关键文件清单 + 架构取舍）/ `coder`（实施，改代码跑命令交结果）/ `code-reviewer`（只读评审，正确性/可读性/架构/安全/性能五维 + 安全审计）。
  - 合并自原来的 10 个（自建 5 + omp 内建 5）：omp `scout` → `explore`；`general-purpose` → `coder`；omp `task` / `sonic` → `coder`；omp 内建 `reviewer` / `security-reviewer` → `code-reviewer`。需要看 omp 内建原始定义时随时 `omp agents unpack --dir <tmp> --json` 重新导出（不入库）。
  - 接入 omp：omp 的任务智能体搜索目录是 `~/.omp/agent/agents/`（**不读** `~/.agents/agents/`），两者靠软链接通——`home/private_dot_omp/agent/agents/symlink_*.md` → `~/.omp/agent/agents/*.md` → `../../../.agents/agents/<name>.md`（chezmoi `apply` 可重建）。
  - 代价：省略 `tools` 后，omp 侧只读角色（`explore` / `plan` / `code-reviewer`）的「只读」降为**提示词约束**而非工具级裁剪。要在 omp 里恢复工具级限制，单独给该 agent 放一份带 `tools:` 的 `~/.omp/agent/agents/<name>.md` 覆盖，**不要**回改本目录（那会破坏跨 harness 通用性）。
- Layout / keymap / housekeeping rationale: `docs/KEYMAP.md`, `home/dot_config/nvim/README.md`, `note.txt`.

## Hosts

- WSL ↔ Windows: Windows host owns wezterm, Wox; everything else lives in WSL under this repo (`~/.dotfiles`). WSL↔Windows sync hooks mirror wezterm config, `shortcuts.json` (overwrite), and `settings/wox.json` (jq deep-merge) to the Windows side.
- Native Linux: wezterm + Wox (Linux build) run directly; no WSL↔Windows step.
- macOS: wezterm + Wox (mac build) run directly; docker via colima (mise-managed).

## rg 优先

User-facing 搜索 / 文件列举一律用 rg；例外见 `note.txt`。 <!-- scan: ignore E3 标题给的是主题，首行给的是适用范围和例外 -->
