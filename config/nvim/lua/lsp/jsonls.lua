-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pylsp

local opts = {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  single_file_support = true,
  init_options = {
    provideFormatter = true
  },
  capabilities = require('lsp.utils').capabilities,
  on_attach = require('lsp.utils').on_attach
}

return opts
