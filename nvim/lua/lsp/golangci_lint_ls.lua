--Enable (broadcasting) snippet capability for completion
local util = require "lspconfig/util"

local opts = {
  cmd = { "golangci-lint-langserver" },
  root_dir = util.root_pattern('go.work') or util.root_pattern('go.mod', '.golangci.yaml', '.git'),
  filetypes = { "go", "gomod" },
  single_file_support = true,
  init_options = {
    command = { "golangci-lint", "run", "--out-format", "json" }
  },
  on_attach = require('lsp.utils').on_attach
}

return opts
