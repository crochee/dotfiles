local util = require "lspconfig/util"
local opts = {
  cmd = { "taplo", "lsp", "stdio" },
  filetypes = { "toml" },
  root_dir = util.root_pattern("*.toml", ".git"),
  single_file_support = true,
  capabilities = require('lsp.utils').capabilities,
  on_attach = require('lsp.utils').on_attach
}

return opts
