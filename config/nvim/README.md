# nvim 配置（0.12+，lazy.nvim）

轻量 + 深度开发集成：LSP / DAP / 测试 / 格式化 / lint 全链路，按需加载。

## 启动结构

```
init.lua                    -- vim.loader.enable() + require("configs")
lua/
├── configs/                -- 基础层（不依赖插件）
│   ├── init.lua            -- lazy.nvim bootstrap + 装载下面四个模块
│   ├── options.lua         -- vim.o.*
│   ├── keymaps.lua         -- 编辑器键位 + blink keymap 注入
│   ├── autocmds.lua        -- vim.lsp.enable + LspAttach 键位 + 通用 autocmd
│   └── lazynvim.lua        -- lazy.nvim 精简配置（defaults.lazy = true）
├── plugins/                -- lazy.nvim specs（键位声明在 spec keys，按需加载）
└── dap/                    -- nvim-dap 约定布局
    ├── adapters/           -- codelldb.lua / delve.lua
    └── configurations/     -- go.lua / llvm.lua (c/cpp/rust)
lsp/                        -- rtp 根原生服务器配置（vim.lsp.enable 自动发现）
ftplugin/go.lua             -- iferr 注入
```

## 插件栈（按职责分组）

- **UI**：bufferline / lualine / dropbar / nvim-tree / nvim-colorizer / flash / render-markdown / trouble / which-key
- **LSP**：mason（`:Mason` 装包）+ mason-tool-installer / 原生 `vim.lsp.config`+`vim.lsp.enable` / rustaceanvim / conform（格式化）/ nvim-lint
- **Treesitter**：nvim-treesitter（main 分支）/ nvim-treesitter-context
- **补全**：blink.cmp + friendly-snippets（原生 `vim.snippet` 引擎）
- **DAP**：nvim-dap / nvim-dap-ui / nvim-dap-virtual-text / nvim-dap-go（`ft=go`）
- **测试**：neotest（go / rust / python / jest 适配器）
- **辅助**：mini.pairs / mini.surround / mini.ai / mini.comment / mini.animate / todo-comments / crates / indent-blankline / auto-session / project.nvim / toggleterm

## 加载策略

- `defaults.lazy = true`：所有插件按 spec 的 `event` / `keys` / `cmd` / `ft` 触发。
- 键位一律声明在 spec 的 `keys` 里 —— 按键即触发加载，未加载前命令不存在的问题不存在。
- 显式急载：colorscheme（priority 1000）、auto-session / project.nvim（会话恢复）、nvim-treesitter（FileType 高亮）。
- 已裁撤：noice + nvim-notify（默认 messages/cmdline 更快）、git-conflict、spaceless、Comment.nvim（→ mini.comment）、mason-lspconfig（→ mason-tool-installer 统一装包）、FixCursorHold.nvim。
