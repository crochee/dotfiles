--Enable (broadcasting) snippet capability for completion
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local opts = {
  cmd = { "vscode-html-language-server", "--stdio" },
  capabilities = capabilities,
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
