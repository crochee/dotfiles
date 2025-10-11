local M = {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  }
}

function M.config()
  local status, telescope = pcall(require, "telescope")
  if not status then
    vim.notify("没有找到 telescope")
    return
  end

  telescope.setup({
    defaults = {
      prompt_prefix = "🔍 ",
      -- 匹配器的命令
      layout_strategy = "vertical",
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--vimgrep",
        "--multiline",
      },

      -- 窗口内快捷键
      mappings = require("configs.keymaps").telescopeList,
    },
  })

  telescope.load_extension("dap")
  telescope.load_extension("zk")
end

return M
