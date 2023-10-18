local M = {
  'Saecki/crates.nvim',
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufRead Cargo.toml" },
}

function M.config()
  local status, crates = pcall(require, "crates")
  if not status then
    vim.notify("没有找到 crates")
    return
  end
  crates.setup({
    src = {
      cmp = { enabled = true },
    },
  })
end

return M
