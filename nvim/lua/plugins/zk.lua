local M = {
  "mickael-menu/zk-nvim",
  main = "zk",
}

-- zk纯文本笔记助手

function M.config()
  require("zk").setup({
    picker = "telescope",

    lsp = {
      -- `config` is passed to `vim.lsp.start_client(config)`
      config = {
        cmd = { "zk", "lsp" },
        name = "zk",
        -- on_attach = ...
        -- etc, see `:h vim.lsp.start_client()`
      },

      -- automatically attach buffers in a zk notebook that match the given filetypes
      auto_attach = {
        enabled = true,
        filetypes = { "markdown" },
      },
    },
  })
  require("telescope").load_extension("zk")
end

return M
