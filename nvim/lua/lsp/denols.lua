vim.g.markdown_fenced_languages = {
  "ts=typescript"
}
local util = require "lspconfig/util"
local opts = {
  cmd = { "deno", "lsp" },
  cmd_env = {
    NO_COLOR = true
  },
  root_dir = util.root_pattern("deno.json", "deno.jsonc", ".git"),
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  init_options = {
    enable = true,
    unstable = false
  },
  single_file_support = true,
  on_attach = require('lsp.utils').on_attach
}

return opts
