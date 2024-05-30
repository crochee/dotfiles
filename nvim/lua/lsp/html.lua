--Enable (broadcasting) snippet capability for completion

local opts = {
  cmd = { "vscode-html-language-server", "--stdio" },
  capabilities = require('lsp.utils').capabilities,
  filetypes = { "html" },
  single_file_support = true,
  init_options = {
    configurationSection = { "html", "css", "javascript" },
    embeddedLanguages = {
      css = true,
      javascript = true
    },
    provideFormatter = true
  },
  on_attach = require('lsp.utils').on_attach
}

return opts
