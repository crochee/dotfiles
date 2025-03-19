local M = {
	"stevearc/conform.nvim",
	event = { "VeryLazy" },
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}

--- Configure Conform
function M.config()
	require("conform").setup({
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "gofumpt", "goimports-reviser", "golines" },
			sql = { "sqlfmt" },
			python = { "ruff_format", "ruff_organize_imports" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			css = { "prettierd", "prettier", stop_after_first = true },
			html = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			jsonc = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
			sh = { "shfmt", "shellcheck" },
			markdown = { "prettierd", "prettier", "injected" },
			toml = { "taplo" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			["c++"] = { "clang-format" },
			["*"] = { "codespell" },
			["_"] = { "trim_whitespace", "trim_newlines" },
		},
		formatters = {
			injected = {
				condition = function(_, ctx)
					local ft = vim.bo[ctx.buf].filetype
					if ft == "checkhealth" then
						return true
					end
					local buf_lang = vim.treesitter.language.get_lang(ft)
					local ok = pcall(vim.treesitter.get_string_parser, "", buf_lang)
					return ok
				end,
			},
		},
	})

	vim.g.diff_format = true
	local diff_format = function()
		if
			not vim.g.diff_format
			or not vim.fn.has("git")
			or vim.api.nvim_get_option_value("filetype", { buf = 0 }) == "lua"
		then
			return
		end

		local buffer_readable = vim.fn.filereadable(vim.fn.bufname("%")) > 0
		if not buffer_readable then
			return
		end

		local format = require("conform").format
		local lines = vim.fn.system("git diff --unified=0 " .. vim.fn.expand("%:p")):gmatch("[^\n\r]+")
		local ranges = {}
		for line in lines do
			if line:find("^@@") then
				local line_nums = line:match("%+.- ")
				if line_nums:find(",") then
					local _, _, first, second = line_nums:find("(%d+),(%d+)")
					table.insert(ranges, {
						start = { tonumber(first), 0 },
						["end"] = { tonumber(first) + tonumber(second) - 1, 0 },
					})
				else
					local first = tonumber(line_nums:match("%d+"))
					table.insert(ranges, {
						start = { first, 0 },
						["end"] = { first + 1, 0 },
					})
				end
			end
		end
		for _, range in pairs(ranges) do
			format({
				lsp_fallback = true,
				timeout_ms = 500,
				range = range,
			})
		end
	end
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*",
		callback = diff_format,
		group = vim.api.nvim_create_augroup("Conform", { clear = true }),
		desc = "Auto format changed lines on save",
	})
	vim.api.nvim_create_user_command("DiffFormat", diff_format, { desc = "Format changed lines" })
	vim.api.nvim_create_user_command("DiffFormatToggle", function()
		vim.g.diff_format = not vim.g.diff_format
		local format_string = vim.g.diff_format and "ON" or "OFF"
		vim.notify("DiffFormat status " .. format_string)
	end, { desc = "toggle DiffFormat" })
end

return M
