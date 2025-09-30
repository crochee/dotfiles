local opts = {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash" },
  single_file_support = true,
  on_attach = require('lsp.utils').on_attach,
  capabilities = require('lsp.utils').capabilities,
}

return opts
