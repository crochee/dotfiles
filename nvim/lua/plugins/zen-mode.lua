local M = {
  'folke/zen-mode.nvim',
  opts = {
    plugins = {
      wezterm = {
        enabled = true,
        -- can be either an absolute font size or the number of incremental steps
        font = "+4", -- (10% increase per step)
      },
    }
  }
}

return M
