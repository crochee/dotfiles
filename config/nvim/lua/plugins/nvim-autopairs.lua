return {
	"windwp/nvim-autopairs",
	config = function()
		-- https://github.com/windwp/nvim-autopairs
		require("nvim-autopairs").setup({
			check_ts = true,
			ts_config = {
				lua = { "string" }, -- it will not add a pair on that treesitter node
				javascript = { "template_string" },
				java = false, -- don't check treesitter on java
			},
		})
		-- If you want insert `(` after select function or method item
		if not vim.g.vscode then
			require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
		end
	end,
}
