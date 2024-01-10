return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  enabled = false,
  config = function()
    require("chatgpt").setup()
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim"
  }
}
