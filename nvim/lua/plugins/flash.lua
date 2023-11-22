local M = {
  'folke/flash.nvim',
  event = 'VeryLazy',
  keys = {
    {
      "<leader>s",
      mode = { "n", "x", "o" },
      function() require("flash").jump() end,
      desc = "Flash"
    },
    {
      "<leader>e",
      mode = { "n", "x", "o" },
      function() require("flash").treesitter() end,
      desc = "Flash Treesitter"
    },
    {
      "<leader>re",
      mode = "o",
      function() require("flash").remote() end,
      desc = "Remote Flash"
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
