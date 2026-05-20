return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		-- 补全源
		"hrsh7th/cmp-vsnip",
		"hrsh7th/vim-vsnip",
	},
	config = function()
		local cmp = require("cmp")
		local kind_icons = {
			Text = "󰉿",
			Method = "󰆧",
			Function = "󰊕",
			Constructor = "",
			Field = " ",
			Variable = "󰀫",
			Class = "󰠱",
			Interface = "",
			Module = "",
			Property = "󰜢",
			Unit = "󰑭",
			Value = "󰎠",
			Enum = "",
			Keyword = "󰌋",
			Snippet = "",
			Color = "󰏘",
			File = "󰈙",
			Reference = "",
			Folder = "󰉋",
			EnumMember = "",
			Constant = "󰏿",
			Struct = "",
			Event = "",
			Operator = "󰆕",
			TypeParameter = " ",
			Misc = " ",
			Codeium = "",
		}

		cmp.setup({
			-- 指定 snippet 引擎
			snippet = {
				expand = function(args)
					-- For `vsnip` users.
					vim.fn["vsnip#anonymous"](args.body)
				end,
			},
			-- 来源
			sources = {
				-- { name = "codeium" },
				{ name = "nvim_lsp" },
				{ name = "vsnip" },
				{ name = "buffer" },
				{ name = "path" },
			},

			-- 快捷键
			mapping = require("configs.keymaps").cmp(cmp),
			formatting = {
				fields = { "kind", "abbr", "menu" },
				format = function(entry, vim_item)
					-- Kind icons
					vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
					vim_item.menu = ({
						nvim_lsp = "[Lsp]",
						vsnip = "[Snippet]",
						buffer = "[Buffer]",
						path = "[Path]",
						-- codeium = "[codeium]",
					})[entry.source.name]
					return vim_item
				end,
			},
		})
		-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
		cmp.setup.cmdline({ "/", "?" }, {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "buffer" },
			},
		})

		-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "path" },
			}, {
				{ name = "cmdline" },
			}),
			matching = { disallow_symbol_nonprefix_matching = false },
		})
	end,
}
