local M = {
  'stevearc/conform.nvim',
}

function M.config()
  require("conform").setup({
    format_on_save = {
      -- These options will be passed to conform.format()
      timeout_ms = 500,
      lsp_fallback = true,
    },
    formatters_by_ft = {
      go = { "golines" },
      sql = { "sqlfmt" },
      python = { "ruff_format" },
    }
  })
end

return M
