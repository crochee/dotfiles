-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pyright
-- 先下载anguage server
-- npm i -g pyright
local util = require "lspconfig/util"
local opts = {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_dir = util.root_pattern(".git"),
  single_file_support = true,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true
      }
    }
  },
  on_attach = require('lsp.utils').on_attach
}

return opts
