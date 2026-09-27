# KEYMAP.md — 统一键位方案 (wezterm + Wox + nvim + omp + shell)

> 五方协同: **wezterm 终端** + **Wox 全局启动器** + **nvim 编辑器** + **omp AI TUI** +
> **shell (readline)**. `mod` = `CTRL` @ Linux/Windows、`SUPER` @ macOS;
> `re_mod` = `SHIFT|mod`. 权威来源, 任何 chord 不在表里都视为自由分配.

## 1. 现状盘点

### 1.1 wezterm (`home/dot_config/wezterm/config/bindings.lua`)

| Chord | Action |
|---|---|
| `F3` / `F4` / `F5` | `ShowLauncher` / `…Args{FUZZY\|TABS}` / `…Args{FUZZY\|WORKSPACES}` |
| `mod+Space` | `ShowLauncher` (终端内命令面板) |
| `re_mod+Space` | `QuickSelect` |
| `mod+;` / `mod+/` / `mod+'` | `QuickSelectArgs` (URL / 前缀) / `OpenWithBrowser` |
| `re_mod+X` / `re_mod+E` | `ActivateCopyMode` / `PaneSelect` |
| `re_mod+K` / `ALT\|SHIFT+K` | `ClearScrollback` (`ScrollbackAndViewport` / `ScrollbackOnly`) |
| `mod+Enter` / `re_mod+Enter` | `SmartSplit` / `CloseCurrentPane{confirm=false}` |
| `mod+←→↑↓` / `re_mod+←→↑↓` | `AdjustPaneSize` resize / `SplitNav` move (zoom-preserving) |
| `F7` | `ActivateKeyTable resize_mode` |

### 1.2 nvim (`home/dot_config/nvim/lua/configs/keymaps.lua` + plugins/*.lua)

| Chord | Mode | Action |
|---|---|---|
| `<Space>` | g | `mapleader` = `<leader>` |
| `<C-s>` | i/x/n/s | save |
| `<leader><Space>` | n | `:noh<CR>` |
| `<leader>ie` | n | toggle LSP inlay hints |
| `<` `>` | v | indent (preserve selection) |
| `<C-\>` | n | toggleterm open/close |
| `<leader>th/tv/ta/tf` | n | toggleterm direction |
| `<leader>tg/tF` | n | lazygit / lazygit current file |
| `<leader>gl` | n/v/x | git log -L 当前行/选区 |
| `<leader>lt` | n/v/x | 当前行/选区送终端 |
| `<C-l>` | n/i (Go buffer) | ftplugin iferr: 光标处生成 error 处理分支 |
| mini.surround | n/x | `gsa/gsd/gsf/gsF/gsh/gsr/gsu` |
| mini.move | n/v | `Alt+h/j/k/l` 移动行/选区 (i 模式仅 `Alt+j/k` 移动行, 见 mini.lua) |
| `q` | n (toggleterm) | close terminal |

> 范围: 本节只盘点**跨层或改键**的 chord; 插件自带 leader 键 (telescope `<leader>ff/fg/…`、
> project `<leader>fp/fP`、bufferline `<leader>q/w/…`、LSP `<leader>rn/ca/gd/…`、dap
> `<leader>dc/…` 等) 是单一工具内部默认, 不参与仲裁, 不在此列。

### 1.3 omp TUI (`OMP_CLAIMS` in bindings.lua)

omp 没有 OSC 通道, 声明是静态映射, 需与 omp `/hotkeys` 手动同步.

| Chord | omp TUI 行为 (典型) |
|---|---|
| `<C-p/r/o/t/g/q/v/l/Enter>` | 模型 / 重试 / 大纲 / 工具输出 / 跳转 / 退出 / 粘贴图 / 清屏 / followUp |
| `<C-S-p/o/v/r>` | 同上变体 |
| `<A-p/m/r/l/a/v/Up>` | 面板 / 历史 / 模型切换 |
| `<A-S-p/l/c/v>` | 同上变体 |
| `<S-Tab>`、`<S-Up>`、`<S-Down>` | 反向 tab / history 滚动 (上下对称) |

### 1.4 shell (`home/dot_inputrc` + `home/private_dot_system/shell.{bash,zsh}.sh.tmpl`)

`dot_inputrc` **不声明任何键** (只做 `set`). 生效的是 readline 默认 +:

```
Up / Down          history-substring-search  (shell.*.sh 覆盖 readline 默认)
C-s                 forward-search-history (stty -ixon 解绑)
C-r                 reverse-history          (mcfly 接管)
```

### 1.5 Wox 全局启动器热键

值定义在 `home/dot_wox/wox-user/settings/wox.json`; 本表是文档, 改值改 wox.json:

| 字段 | Windows | macOS | Linux |
|---|---|---|---|
| `MainHotkey` | `alt+space` | `cmd+space` | `alt+space` |
| `SelectionHotkey` | `win+alt+space` | `command+option+space` | `ctrl+shift+alt+space` |
| `ActionPanelHotkey` | `ctrl+k` | `cmd+k` | `ctrl+k` |

`alt+space` (Win/Linux) 是 Wox v2 默认; 与 wezterm `mod+Space` (Linux 上 = `ctrl+space`) 不冲突.

## 2. 冲突矩阵与判定

| Chord | wezterm | omp | nvim | shell | Wox | **裁定** |
|---|---|---|---|---|---|---|
| `mod+Space` | ShowLauncher | — | `<leader>`=Space | — | — | **wezterm** |
| `re_mod+K` / `ALT\|SHIFT+K` | ClearScrollback | — | — | `C-k` kill to EOL | `ActionPanelHotkey=ctrl+k` | 不冲突 (修饰/焦点不同) |
| `mod+\` | 不绑 (wezterm 不设 leader, 不消费任何 `\` chord) | — | `<C-\>` toggleterm | — | — | **nvim** |
| `mod+P/R/O/T/G/V/L/Q` | — | omp claim | — | — | — | **omp** (仅 omp TUI 内; macOS 上 `mod`=SUPER, 不命中 CTRL 字面 claim) |
| `mod+Enter` | SmartSplit (借出, §6) | omp followUp (焦点在 omp 时 dispatch 转发) | — | — | — | **wezterm→omp** |
| `Alt+Space` (Win/Linux) | — | — | — | — | `MainHotkey` | **Wox** (全局焦点) |
| `Alt+H/J/K/L` | — | — | mini.move | — | — | **nvim** (焦点在 nvim 内) |
| `Alt+P/M/R/L/A/V/Up` | — | omp claim | — | — | — | **omp** (TUI 内) |
| `Alt+BS`、`Alt+T` | — | — | — | readline | — | **shell** |
| `Win+Alt+Space` (Win)、`Ctrl+Shift+Alt+Space` (Linux) | — | — | — | — | `SelectionHotkey` | **Wox** (划词触发) |
| `re_mod+P` / `re_mod+L` | — | `<C-S-p>` omp | — | — | — | **无** (Wox 的 pwp/pwu/pwip/pwl 是 query 文本触发, 非 chord) |
| `Ctrl+P`… (单键) | — | omp claim | — | readline 历史 | — | 按焦点裁决 (见下) |

**Ctrl 单键与上下键**: readline 与 omp 都想用 `C-p/r/o/t/g/q/v/l/enter`. 普通 shell prompt
readline 赢 (`C-p` = 上一条历史), omp TUI 内 omp 赢 (`C-p` = 模型选择) ——
`OMP_CLAIMS` + `dispatch()` 在按下时问焦点 pane 谁认领, 未认领才走 wezterm 动作.

## 3. 裁决依据

冲突时按使用频率让位 (高→低): **readline 行编辑 > nvim mini.move > wezterm 分屏/标签 >
omp TUI 内单键 > 启动器 (Wox 不与任何终端/编辑器键重叠)**.

## 4. 验证清单 (改键后必跑)

1. **shell prompt**: 上下箭头回放历史、`C-a/e` 跳行首尾、`C-k/u` 删段、`Alt+BS` 删词.
2. **omp TUI**: `Shift+Up`/`Shift+Down` **对称**滚动 history; `Ctrl+P` 弹模型选择; `Ctrl+L` 清屏.
3. **wezterm**: `mod+Space` 弹 cmd palette; `mod+;` 弹 URL picker; `re_mod+K` 清屏; `re_mod+arrows` 切分屏.
4. **nvim**: `Alt+J/K` 在 visual 模式移动选区; `<C-\>` 开关 toggleterm; `<leader>tg` 弹 lazygit.
5. **Wox**: `alt+space` (Win/Linux) / `cmd+space` (macOS) 全局弹出; wezterm 内 `alt+space` 不触发
   wezterm 任何动作 (`mod+Space` 是不同修饰).
6. **WSL→Windows 同步** (WSL 主机专属): 改 `home/dot_wox/wox-user/settings/wox.json` 后跑一次 apply,
   确认 Windows 侧 `yq '.["MainHotkey@windows"]' "/mnt/c/Users/$USER/.wox/wox-user/settings/wox.json"`
   反映新值.
7. **不冲突验证**: shell 内 `Ctrl+P` 不应触发 omp 命令面板 (焦点不在 omp, `dispatch` 不命中).

## 5. 已知 trade-off

1. **macOS Spotlight vs Wox**: `cmd+space` 抢占 Spotlight, 属用户选择. 恢复 Spotlight:
   System Settings → Keyboard → Keyboard Shortcuts → Spotlight, 或改 Wox 的 `MainHotkey`.
2. **omp followUp 的 Ctrl+Enter**: wezterm 把 `mod+Enter` 借给 SmartSplit; omp 有 `Ctrl+Q` fallback.
3. **Alt+H/J/K/L**: 与系统 IME 的 Alt 切换潜在冲突 — 本机未启用 fcitx/IBus, 无影响.
4. **Wox 与 dotfiles**: 本仓只镜像 Wox *store* (`ShellCommands.json` + `settings/wox.json`),
   不管理 Wox 主程序与第三方插件. Wox 是 Windows 原生程序, 通过 `\\wsl$\<distro>\...`
   访问 WSL 文件 (Wox Everything 等插件用户自装).