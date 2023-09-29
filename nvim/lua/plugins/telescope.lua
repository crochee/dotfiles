local M = {
  'nvim-telescope/telescope.nvim',
  tag = "0.1.2",
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-dap.nvim',
  }
}

function M.config()
  local status, telescope = pcall(require, "telescope")
  if not status then
    vim.notify("没有找到 telescope")
    return
  end

  -- local actions = require("telescope.actions")
  telescope.setup({
    defaults = {
      prompt_prefix = "🔍 ",
      layout_strategy = "horizontal",
      -- 匹配器的命令
      vimgrep_arguments = { "rg", "--vimgrep", "--smart-case", "--multiline" },
      -- 窗口内快捷键
      mappings = require("configs.keymaps").telescopeList,
    },
    pickers = {
      find_files = {
        -- theme = "dropdown", -- 可选参数： dropdown, cursor, ivy
      }
    },
    extensions = {
    },
  })

  pcall(telescope.load_extension, "dap")
  pcall(telescope.load_extension, "dotfiles")
  pcall(telescope.load_extension, "projects")
end

return M
