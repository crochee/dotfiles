local M = {
	"stevearc/conform.nvim",
	event = { "VeryLazy" },
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}

function M.config()
	local prettier = { "prettierd", "prettier", stop_after_first = true }
	require("conform").setup({
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "golines", "gofmt" },
			sql = { "sqlfmt" },
			python = { "ruff_format" },
			javascript = prettier,
			typescript = prettier,
			javascriptreact = prettier,
			typescriptreact = prettier,
			css = prettier,
			html = prettier,
			json = prettier,
			jsonc = prettier,
			yaml = prettier,
			sh = { "shfmt" },
			markdown = { prettier, "injected", stop_after_first = true },
			toml = { "taplo" },
		},
		formatters = {
			-- Dealing with old version of prettierd that doesn't support range formatting
			injected = {
				options = {
					-- Set to true to ignore errors
					ignore_errors = false,
					-- Map of treesitter language to file extension
					-- A temporary file name with this extension will be generated during formatting
					-- because some formatters care about the filename.
					lang_to_ext = {
						bash = "sh",
						c_sharp = "cs",
						elixir = "exs",
						javascript = "js",
						julia = "jl",
						latex = "tex",
						markdown = "md",
						python = "py",
						ruby = "rb",
						rust = "rs",
						teal = "tl",
						typescript = "ts",
					},
					-- Map of treesitter language to formatters to use
					-- (defaults to the value from formatters_by_ft)
					lang_to_formatters = {},
				},
			},
			prettierd = {
				range_args = false,
			},
		},
	})

	vim.g.diff_format = true
	local diff_format = function()
		if not vim.g.diff_format then
			return
		end

		local buffer_readable = vim.fn.filereadable(vim.fn.bufname("%")) > 0
		if not vim.fn.has("git") or not buffer_readable then
			return
		end

		local format = require("conform").format
		local ignore_filetypes = { "lua" }
		if vim.tbl_contains(ignore_filetypes, vim.api.nvim_get_option_value("filetype", { buf = 0 })) then
			format({
				lsp_fallback = true,
				timeout_ms = 500,
			})
			return
		end
		local lines = vim.fn.system("git diff --unified=0 " .. vim.fn.expand("%:p")):gmatch("[^\n\r]+")
		local ranges = {}
		for line in lines do
			if line:find("^@@") then
				local line_nums = line:match("%+.- ")
				if line_nums:find(",") then
					local _, _, first, second = line_nums:find("(%d+),(%d+)")
					table.insert(ranges, {
						start = { tonumber(first), 0 },
						["end"] = { tonumber(first) + tonumber(second) + 1, 0 },
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
