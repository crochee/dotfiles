local M = {
  'lewis6991/gitsigns.nvim'
}

function M.config()
  require('gitsigns').setup {
    on_attach = function(bufnr)
      local function map(mode, lhs, rhs, opts)
        opts = vim.tbl_extend('force', { noremap = true, silent = true }, opts or {})
        vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
      end

      -- 绑定快捷键
      require("configs.keymaps").mapgit(map)
    end }
end

return M
