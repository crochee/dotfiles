return {
	"saghen/blink.cmp",
	version = "1.*",
	event = "InsertEnter",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	opts = {
		snippets = { preset = "default" },
		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 500 },
			accept = { auto_brackets = { enabled = true } },
			menu = {
				-- nvim-cmp-style 2-column layout: label + source.
				draw = {
					columns = { { "label", "label_description", gap = 1 }, { "kind_icon" } },
				},
			},
		},
		sources = {
			-- List builtin sources under `providers` explicitly. health.lua indexes
			-- config.sources.providers and nil-derefs if default sources are missing.
			default = { "lsp", "path", "snippets", "buffer" },
			providers = {
				lsp = { name = "LSP", module = "blink.cmp.sources.lsp" },
				path = { name = "Path", module = "blink.cmp.sources.path" },
				snippets = { name = "Snippets", module = "blink.cmp.sources.snippets" },
				buffer = { name = "Buffer", module = "blink.cmp.sources.buffer" },
			},
		},
		-- keymap: default preset handles <C-space>/<C-e>/<C-n>/<C-p>/etc; only override
		-- the three custom bindings.
		keymap = {
			preset = "default",
			["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
			["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
			["<CR>"] = {
				function(c)
					if not c.is_visible() then return nil end
					if c.get_selected_item() ~= nil then return c.accept() end
					local items = c.get_items()
					if items and #items == 1 then return c.accept({ index = 1 }) end
					return nil
				end,
				"fallback",
			},
		},
	},
}
