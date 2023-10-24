local M = {
  'folke/flash.nvim',
  event = 'VeryLazy',
  keys = {
    {
      "s",
      mode = { "n", "x", "o" },
      function() require("flash").jump() end,
      desc = "Flash"
    },
    {
      "S",
      mode = { "n", "x", "o" },
      function() require("flash").treesitter() end,
      desc = "Flash Treesitter"
    },
    {
      "<leader>fr",
      mode = { "n", "o", "x" },
      function() require("flash").treesitter_search() end,
      desc = "Treesitter Search"
    },
  },
}

function M.config()
  require('flash').setup({
    modes = {
      char = {
        enabled = false,
      }
    }
  })
end

return M
