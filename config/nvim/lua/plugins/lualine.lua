local M = {
  'nvim-lualine/lualine.nvim',
}
-- 底部状态栏
function M.config()
  local spaces = function()
    return vim.api.nvim_buf_get_option(0, "shiftwidth")
  end

  local lsp = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients { bufnr = bufnr }

    if next(clients) == nil then
      return 'No Active Lsp'
    end
    return require('lsp-status').status():gsub("%%", "")
  end
  local codeium = function()
    return vim.api.nvim_call_function("codeium#GetStatusString", {})
  end
  require('lualine').setup {
    options = {
      disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
      component_separators = '',
      section_separators = '',
    },
    sections = {
      lualine_c = {
        {
          'filename',
          file_status = true, -- displays file status (readonly status, modified status)
          path = 1            -- 0 = just filename, 1 = relative path, 2 = absolute path
        }
      },
      lualine_x = {
        lsp,
        codeium,
        spaces,
        "encoding",
        {
          "filetype",
          icons_enabled = true,
        },
      },
    },
  }
end

return M
