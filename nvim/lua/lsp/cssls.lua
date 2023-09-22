--Enable (broadcasting) snippet capability for completion
local util = require "lspconfig/util"
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local opts = {
  cmd = { "vscode-css-language-server", "--stdio" },
  capabilities = capabilities,
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
  on_attach = require('lsp.utils').on_attach
}

return opts
