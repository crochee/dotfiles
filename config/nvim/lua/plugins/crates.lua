local M = {
  'Saecki/crates.nvim',
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufRead Cargo.toml" },
}

function M.config()
  require("crates").setup({
    src = {
      cmp = { enabled = true },
    },
  })
end

return M
