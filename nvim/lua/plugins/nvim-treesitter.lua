local M = {
  'nvim-treesitter/nvim-treesitter',
  commit = '6847ce4f8c93a0c8fd5a3d4df08975ab185187eb',
  build = ':TSUpdate',
}

function M.config()
  require('nvim-treesitter.configs').setup {
    -- 安装 language parser
    -- :TSInstallInfo 命令查看支持的语言
    ensure_installed = {
      "lua",
      "go",
      "gomod",
      "gowork",
      "make",
      "json",
      "css",
      "scss",
      "bash",
      "javascript",
      "tsx",
      "rust",
      "markdown",
      "make",
      "sql",
      "toml",
      "vim",
      "todotxt",
      "python",
      "dockerfile",
      "yaml",
      "html",
      "regex",
    },
    -- 启用代码高亮功能
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false
    },
    -- incremental_selection = {
    --   enable = true,
    --   keymaps = {
    --     init_selection = '<CR>',
    --     node_incremental = '<CR>',
    --     node_decremental = '<BS>',
    --     scope_incremental = '<TAB>',
    --   }
    -- },
    -- 启用基于Treesitter的代码格式化(=) . NOTE: This is an experimental feature.
    indent = {
      enable = false
    }
  }
  -- 开启 Folding
  -- vim.wo.foldmethod = 'expr'
  -- vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
  -- 默认不要折叠
  -- https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
  -- vim.wo.foldlevel = 99
end

return M
