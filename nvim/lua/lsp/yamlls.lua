local opts = {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose" },
  single_file_support = true,
  on_attach = require('lsp.utils').on_attach,
  capabilities = require('lsp.utils').capabilities,
  settings = {
    redhat = {
      telemetry = {
        enabled = false
      }
    }
  }
}
return opts
