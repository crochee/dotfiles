local util = require "lspconfig/util"
local opts = {
  cmd = { "sql-language-server", "up", "--method", "stdio" },
  filetypes = { "sql", "mysql" },
  on_attach = require('lsp.utils').on_attach
}

return opts
