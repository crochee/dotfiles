local util = require "lspconfig/util"
local opts = {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  root_dir = util.root_pattern("tsconfig.json", "package.json", "jsconfig.json", ".git"),
  single_file_support = true,
  capabilities = require('lsp.utils').capabilities,
  on_attach = require('lsp.utils').on_attach,
}

return opts
