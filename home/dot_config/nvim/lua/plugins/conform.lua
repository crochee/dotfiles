return {
	"stevearc/conform.nvim",
	keys = {
		{
			"<leader>fm",
			function()
				require("conform").format({ async = true, lsp_fallback = true }, function(err)
					if err then
						vim.notify("format error: " .. tostring(err), vim.log.levels.WARN)
					end
				end)
			end,
			mode = { "n", "v" },
			desc = "Format code",
		},
		{ "<leader>=", "<cmd>DiffFormat<cr>", desc = "Format changed lines" },
	},
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
	--- Configure Conform
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "gofumpt", "goimports-reviser" },
				rust = { "rustfmt" },
				sql = { "sqlfmt" },
				python = { "ruff_format", "ruff_organize_imports" },
				javascript = { "biome" },
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },
				css = { "biome" },
				html = { "biome" },
				json = { "biome" },
				jsonc = { "biome" },
				yaml = { "biome" },
				sh = { "shfmt" },
				markdown = { "prettier", "injected" },
				toml = { "taplo" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				["_"] = { "trim_whitespace", "trim_newlines" },
			},
		formatters = {
			-- biome handles json/jsonc/yaml/js/ts/jsx/tsx/css/html via one binary.
			-- conform runs `biome format $FILENAME` and auto-cd's to dirname for biome.json.
			["biome"] = {
				args = { "format", "--write", "$FILENAME" },
				-- Force stdin=false: tbl_deep_extend inherits conform's builtin stdin=true,
				-- and `--write` writes in place — stdin mode would treat stdout (summary)
				-- as the formatted buffer (data loss).
				stdin = false,
			},
			-- injected: conform's built-in treesitter detection supersedes any hand-rolled
			-- condition we might write.
		},
	})

		vim.g.diff_format = true
		local diff_format = function()
			if
				not vim.g.diff_format
				or vim.fn.executable("git") == 0
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
	end,
}
