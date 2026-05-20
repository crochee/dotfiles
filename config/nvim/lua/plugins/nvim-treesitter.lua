local function is_parser_installed(lang)
	local installed = require("nvim-treesitter").get_installed()
	return vim.tbl_contains(installed, lang)
end

local function is_parser_available(lang)
	local available = require("nvim-treesitter").get_available()
	return vim.tbl_contains(available, lang)
end

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
	-- Treesitter is a new parser generator tool that we can
	-- use in Neovim to power faster and more accurate
	-- syntax highlighting.
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(ev)
					local lang = vim.treesitter.language.get_lang(ev.match)
					if not lang then
						return
					end
					local buf = ev.buf
					if is_parser_installed(lang) then
						start_treesitter(buf, lang)
					elseif is_parser_available(lang) then
						require("nvim-treesitter").install(lang):await(function()
							start_treesitter(buf, lang)
						end)
					end
				end,
			})
		end,
	},
	-- Show context of the current function
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = { "VeryLazy" },
		opts = { mode = "cursor", max_lines = 3 },
	},
}
