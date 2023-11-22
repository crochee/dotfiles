--Enable (broadcasting) snippet capability for completion
local util = require "lspconfig/util"

local opts = {
  cmd = { "vscode-css-language-server", "--stdio" },
  root_dir = util.root_pattern("package.json", ".git"),
  filetypes = { "css", "scss", "less" },
  single_file_support = true,
  settings = {
    css = {
      validate = true
    },
    less = {
      validate = true
    },
    scss = {
      validate = true
    }
  },
  capabilities = require('lsp.utils').capabilities,
  on_attach = require('lsp.utils').on_attach
}

return opts
