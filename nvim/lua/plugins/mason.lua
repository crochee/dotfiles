local M = {
  'williamboman/mason.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nanotee/sqls.nvim',
    'b0o/schemastore.nvim',
    ------ lsp
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    -------- dap
    'jayp0521/mason-nvim-dap.nvim',
    'mfussenegger/nvim-dap',
    "theHamsta/nvim-dap-virtual-text",
    "rcarriga/nvim-dap-ui",
    'leoluz/nvim-dap-go',
    'theHamsta/nvim-dap-virtual-text',
    "rcarriga/nvim-dap-ui",
    'simrat39/rust-tools.nvim',
  }
}

function M.config()
  local status, mason = pcall(require, "mason")
  if not status then
    vim.notify("Plugin `mason.nvim` not found")
    return
  end

  mason.setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    },
    -- ~/.local/share/nvim/mason
    install_root_dir = vim.fn.stdpath("data") .. "/mason",
  })


  -----------------dap Install List ---------------------
  local mason_dap
  status, mason_dap = pcall(require, "mason-nvim-dap")
  if not status then
    vim.notify("Plugin `mason-nvim-dap` not found")
    return
  end

  require("telescope").load_extension("dap")

  -- import dap's config
  require("daps.config")
  local list = {
    {
      name = "delve",
      alone = true,
      need_installed = true,
    },
    {
      name = "codelldb",
      alone = true,
      need_installed = true,
    }
  }

  local handlers = {}
  local alones = {}
  local sources = {}

  for _, ele in pairs(list) do
    if ele.need_installed then
      table.insert(sources, ele.name)
    end

    if ele.alone then
      table.insert(alones, "daps.configs." .. ele.name)
    else
      handlers[ele.name] = require("daps.configs." .. ele.name)
    end
  end

  -- list the debug dependence that must be installed
  mason_dap.setup({
    ensure_installed = sources,
    automatic_installation = true,
    handlers = handlers,
  })

  for _, ele in pairs(alones) do
    require(ele)
  end

  -------------------- LSP Install List
  -- https://github.com/williamboman/nvim-lsp-installer#available-lsps
  -- { key: lsp_name, value: lsp_config }
  local mason_lspconfig
  status, mason_lspconfig = pcall(require, "mason-lspconfig")
  if not status then
    vim.notify("Plugin `mason-lspconfig` not found")
    return
  end

  local lspconfig
  status, lspconfig = pcall(require, "lspconfig")
  if not status then
    vim.notify("Plugin `lspconfig` not found")
    return
  end
  local servers = {
    gopls = require("lsp.gopls"),
    rust_analyzer = require("lsp.rust_analyzer"),
    lua_ls = require("lsp.lua"),
    bashls = require("lsp.bashls"),
    jsonls = require("lsp.jsonls"),
    pyright = require("lsp.pyright"),
    vimls = require("lsp.vimls"),
    cssls = require("lsp.cssls"),
    html = require("lsp.html"),
    golangci_lint_ls = require("lsp.golangci_lint_ls"),
    denols = require("lsp.denols"),
    eslint = require("lsp.eslint"),
  }

  local ensure_installed = { type = "list" }
  for name, _ in pairs(servers) do
    table.insert(ensure_installed, name)
  end

  mason_lspconfig.setup({
    ensure_installed = ensure_installed,
    automatic_installation = true,
  })

  -- 加载配置
  for name, config in pairs(servers) do
    if config.setup then
      -- config删除setup元素
      local opts = vim.tbl_deep_extend("force", config, {
        setup = nil,
      })
      config.setup(opts)
    else
      lspconfig[name].setup(config)
    end
  end
end

return M
