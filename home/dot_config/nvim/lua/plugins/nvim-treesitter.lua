-- nvim-treesitter (main 分支): 高亮/fold 由 Neovim 内置 vim.treesitter 提供,
-- 插件只管 parser 的安装/更新. FileType 时: 已装 → start; 未装但可装 → 异步
-- 安装后 start. 这是 README "Supported features" 一节给出的官方接法.
local function start_treesitter(buf, lang)
	if not vim.treesitter.language.add(lang) then
		vim.notify("Cannot load treesitter parser for language " .. lang, vim.log.levels.WARN)
		return
	end
	vim.treesitter.start(buf)
	vim.bo[buf].syntax = "ON"
	if vim.treesitter.query.get(lang, "indents") then
		vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(ev)
					local lang = vim.treesitter.language.get_lang(ev.match)
					if not lang then
						return
					end
					local ts = require("nvim-treesitter")
					if vim.list_contains(ts.get_installed(), lang) then
						start_treesitter(ev.buf, lang)
					elseif vim.list_contains(ts.get_available(), lang) then
						ts.install(lang):await(function()
							start_treesitter(ev.buf, lang)
						end)
					end
				end,
			})
		end,
	},
	-- Show context of the current function
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "VeryLazy",
		keys = {
			{ "<leader>tc", function() require("treesitter-context").go_to_context() end, desc = "Jump to context" },
		},
		opts = { mode = "cursor", max_lines = 3 },
	},
}
