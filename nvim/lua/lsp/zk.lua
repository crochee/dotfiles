-- zk纯文本笔记助手

return {
  setup = function(opts)
    require("zk").setup({
      picker = "telescope",
    })
  end,
}
