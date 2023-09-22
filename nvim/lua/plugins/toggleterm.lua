local M = {
  'akinsho/toggleterm.nvim',
}
function M.config()
  local status, toggleterm = pcall(require, "toggleterm")
  if not status then
    vim.notify('没有找到 toggleterm')
    return
  end


  toggleterm.setup({
    open_mapping = "<leader>tt",
    hide_numbers = true,
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    persist_size = true,
    direction = 'float',
    close_on_exit = true,
    shell = vim.o.shell,
    float_opts = {
      border = "double", -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
      winblend = 3,
      highlights = {
        border = "Normal",
        background = "Normal",
      },
    },
    winbar = {
      enabled = true,
      name_formatter = function(term) --  term: Terminal
        return term.name
      end
    },
  })
  local Terminal = require("toggleterm.terminal").Terminal

  -- local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })
  local lazygit = Terminal:new({
    id = 1000, --[[ 解决lazygit关闭通用窗口问题 ]]
    cmd = "lazygit",
    dir = "git_dir",
    direction = "float",
    float_opts = {
      border = "curved", -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
    },
    -- function to run on opening the terminal
    on_open = function(term)
      vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
    end,
  })

  function _LAZYGIT_TOGGLE()
    lazygit:toggle()
  end

  local gitui = Terminal:new({
    id = 1001, --[[ 解决gitui关闭通用窗口问题 ]]
    cmd = "gitui",
    direction = "float",
    float_opts = {
      border = "curved", -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
    },
  })

  function _GITUI_TOGGLE()
    gitui:toggle()
  end
end

return M
