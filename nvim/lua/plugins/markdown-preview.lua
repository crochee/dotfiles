local M = {
  "iamcco/markdown-preview.nvim",
  -- -- install without yarn or npm
  -- build = function() vim.fn["mkdp#util#install"]() end,
  -- -- install with yarn or npm
  build = "cd app && npm install",
  lazy = true,
  ft = { "markdown", "markdown.mkd" },
}

function M.config()
  vim.g.mkdp_echo_preview_url = true
  vim.g.mkdp_theme = "light"
  vim.g.mkdp_filetypes = { "markdown", "markdown.mkd" }
  vim.g.markdown_fenced_languages = {
    'html',
    'bash=sh',
    'css',
    'javascript',
    'js=javascript',
    'typescript',
    'awk',
    'lua',
    'stylus',
    'vim',
    'help',
    'yaml'
  }
end

return M
