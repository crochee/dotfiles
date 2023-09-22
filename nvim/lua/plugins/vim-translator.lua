local M = {
  'voldikss/vim-translator',
  event = 'VeryLazy',
  enabled = false
}

function M.config()
  vim.g.translator_target_lang = 'zh'
end

return M
