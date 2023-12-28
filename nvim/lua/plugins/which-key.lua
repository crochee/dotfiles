local M = {
  'folke/which-key.nvim',
  event = 'VeryLazy',
}

function M.config()
  vim.o.timeout = true
  vim.o.timeoutlen = 300
  local wk = require('which-key')
  local status, chatgpt = pcall(require, "chatgpt")
  if status then
    wk.register({
      p = {
        name = "ChatGPT",
        e = {
          function()
            chatgpt.edit_with_instructions()
          end,
          "Edit with instructions",
        },
      },
    }, {
      prefix = "<leader>",
      mode = "v",
    })
  end
  wk.setup({
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    plugins = {
      spelling = {
        enabled = false,
      },
    }
  })
end

return M
