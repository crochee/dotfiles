local M = {
}

function M.on_attach(client, bufnr)
  -- 禁用格式化功能，交给专门插件插件处理
  -- client.resolved_capabilities.document_formatting = false
  -- client.resolved_capabilities.document_range_formatting = false
  local function buf_set_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ...)
  end

  -- Enable completion triggered by <c-x><c-o>
  vim.opt.omnifunc = 'v:lua.vim.lsp.omnifunc'
  client.server_capabilities.semanticTokensProvider = nil

  -- 绑定快捷键
  require("configs.keymaps").maplsp(buf_set_keymap)

  local lsp_status = require('lsp-status')
  lsp_status.on_attach(client)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
local lsp_status = require('lsp-status')
M.capabilities = vim.tbl_extend('keep', capabilities or {}, lsp_status.capabilities)

return M
