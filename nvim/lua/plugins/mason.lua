local M = {
  'williamboman/mason.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'b0o/schemastore.nvim',
    ------ lsp
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    'nanotee/sqls.nvim',
    -------- dap
    'nvim-telescope/telescope-dap.nvim',
    'jayp0521/mason-nvim-dap.nvim',
    'mfussenegger/nvim-dap',
    "theHamsta/nvim-dap-virtual-text",
    "rcarriga/nvim-dap-ui",
    'leoluz/nvim-dap-go',
    'theHamsta/nvim-dap-virtual-text',
    "rcarriga/nvim-dap-ui",
    'simrat39/rust-tools.nvim',
    ----------linter
    {
      "jay-babu/mason-null-ls.nvim",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = {
        "williamboman/mason.nvim",
        "jose-elias-alvarez/null-ls.nvim",
      },
      config = function()
      end,
    }
  }
}

function M.config()
  require("mason").setup({
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
  -- import dap's config
  require("daps.config")
  local dap_list = {
    {
      name = "delve",
      alone = true,
    },
    {
      name = "codelldb",
      alone = true,
    }
  }

  local dap_handlers = {}
  local dap_ensure_installed = {}

  for _, ele in pairs(dap_list) do
    table.insert(dap_ensure_installed, ele.name)

    if ele.alone then
      require("daps.configs." .. ele.name)
    else
      dap_handlers[ele.name] = require("daps.configs." .. ele.name)
    end
  end

  -- list the debug dependence that must be installed
  require("mason-nvim-dap").setup({
    ensure_installed = dap_ensure_installed,
    automatic_installation = true,
    handlers = dap_handlers,
  })

  -------------------- LSP Install List
  -- https://github.com/williamboman/nvim-lsp-installer#available-lsps
  -- { key: lsp_name, value: lsp_config }
  local lsp_servers = {
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
    eslint = require("lsp.eslint"),
    tsserver = require("lsp.tsserver"),
    taplo = require("lsp.taplo"),
    sqlls = require("lsp.sqlls"),
    yamlls = require("lsp.yamlls"),
  }

  local lsp_ensure_installed = { type = "list" }
  for name, config in pairs(lsp_servers) do
    table.insert(lsp_ensure_installed, name)
    if config.setup then
      -- config删除setup元素
      local opts = vim.tbl_deep_extend("force", config, {
        setup = nil,
      })
      config.setup(opts)
    else
      require("lspconfig")[name].setup(config)
    end
  end

  -- linters
  require("mason-lspconfig").setup({
    ensure_installed = lsp_ensure_installed,
    automatic_installation = true,
  })

  -------------------- Linter Install List
  local linters = {
    shellcheck = require("linter.shellcheck"),
    golangci_lint = {},
    vacuum = {},
    stylelint = {},
  }
  local linter_ensure_installed = { type = "list" }
  for name, _ in pairs(linters) do
    table.insert(linter_ensure_installed, name)
  end

  require("null-ls").setup()
  require("mason-null-ls").setup({
    ensure_installed = linter_ensure_installed,
    automatic_installation = true,
  })
end

return M
