local M = {
  "mickael-menu/zk-nvim",
  main = "zk",
  dependencies = {
    'plasticboy/vim-markdown',
    branch = 'master',
    require = { 'godlygeek/tabular' },
  }
}

-- zk纯文本笔记助手

function M.config()
  require("zk").setup({
    picker = "telescope",
  })
end

return M
