local opts = {
  cmd          = { "sql-language-server", "up", "--method", "stdio" },
  filetypes    = { "sql", "mysql" },
  capabilities = require('lsp.utils').capabilities,
  on_attach    = require('lsp.utils').on_attach
}

return opts
