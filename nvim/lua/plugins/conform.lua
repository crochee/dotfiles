local M = {
  'stevearc/conform.nvim',
}

function M.config()
  require("conform").setup()
  -- 保存时自动格式化
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = "*",
    callback = function(args)
      require("conform").format({ bufnr = args.buf })
    end,
  })
end

return M
