-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#rust_analyzer
local util = require('lspconfig/util')

local opts = {
  cmd = { "rust-analyzer" },
  filetyps = { "rust" },
  root_dir = util.root_pattern("Cargo.toml", "rust-project.json"),
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        runBuildScripts = true,
        buildScripts = {
          enable = true,
        },
      },
      -- Add clippy lints for Rust.
      checkOnSave = {
        allFeatures = true,
        command = "clippy",
        extraArgs = { "--no-deps" },
      },
      procMacro = {
        enable = true,
        ignored = {
          ["async-trait"] = { "async_trait" },
          ["napi-derive"] = { "napi" },
          ["async-recursion"] = { "async_recursion" },
        },
      },
    },
  },
  on_attach = require('lsp.utils').on_attach,
  setup = function(opts)
    local rust_tools_opts = require("util").opts("rust-tools.nvim")
    require("rust-tools").setup(vim.tbl_deep_extend("force", rust_tools_opts or {}, {
      server = opts,
      dap = {
        adapter = require("dap").adapters.codelldb,
      },
      tools = {
        on_initialized = function()
          vim.cmd([[
                 augroup RustLSP
                   autocmd CursorHold                      *.rs silent! lua vim.lsp.buf.document_highlight()
                   autocmd CursorMoved,InsertEnter         *.rs silent! lua vim.lsp.buf.clear_references()
                   autocmd BufEnter,CursorHold,InsertLeave *.rs silent! lua vim.lsp.codelens.refresh()
                 augroup END
               ]])
        end,
      },
    }))
  end,
}

return opts
