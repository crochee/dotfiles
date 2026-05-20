-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pylsp
return {
  capabilities = require('lsp.utils').capabilities,
  on_attach = require('lsp.utils').on_attach
}
