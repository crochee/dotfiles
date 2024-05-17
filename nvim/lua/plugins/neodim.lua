local M = {
  "zbirenbaum/neodim",
  event = "LspAttach",
}
-- 未使用变量置暗
function M.config()
  require("neodim").setup({
    refresh_delay = 75,
    alpha = 0.75,
    blend_color = "#000000",
    hide = {
      underline = true,
      virtual_text = true,
      signs = true,
    },
    regex = {
      "[uU]nused",
      "[nN]ever [rR]ead",
      "[nN]ot [rR]ead",
      cs = {
        "CS8019",
      },
      -- disable `regex` option when filetype is "rust"
      rust = {},
    },
    priority = 128,
    disable = {},
  })
end

return M
