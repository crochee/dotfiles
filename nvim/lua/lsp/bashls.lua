local opts = {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh" },
  single_file_support = true,
  on_attach = require('lsp.utils').on_attach
}

return opts
