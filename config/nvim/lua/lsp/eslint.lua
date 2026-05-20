-- npm i -g vscode-langservers-extracted
local opts = {
  capabilities = require('lsp.utils').capabilities,
  on_attach = function(client, bufnr)
    require('lsp.utils').on_attach(client, bufnr)
    vim.api.nvim_buf_create_user_command(0, 'LspEslintFixAll', function()
      client:request_sync('workspace/executeCommand', {
        command = 'eslint.applyAllFixes',
        arguments = {
          {
            uri = vim.uri_from_bufnr(bufnr),
            version = vim.lsp.util.buf_versions[bufnr],
          },
        },
      }, nil, bufnr)
    end, {})
  end
}

return opts
