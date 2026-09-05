return {
	"saghen/blink.cmp",
	version = "1.*",
	event = "InsertEnter",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	opts = {
		-- keymap handled via blink.cmp mappings; we extend with confirm-and-autopairs
		snippets = { preset = "default" },
		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 500 },
			accept = { auto_brackets = { enabled = true } },
			menu = {
				-- nvim-cmp-style 2-column layout: label + source
				draw = {
					columns = { { "label", "label_description", gap = 1 }, { "kind_icon" } },
				},
			},
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},
		-- blink.cmp 1.x：keymap 是 table（key → 命令链），命令返回 false/nil 落到下一项
		keymap = {
			["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
			["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
			["<C-Space>"] = { "show", "show_documentation" },
			["<C-e>"] = { "cancel", "fallback" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
			["<CR>"] = {
				function(c)
					if not c.is_visible() then
						return nil
					end
					-- 显式选中某个候选 → 原样 accept
					if c.get_selected_item() ~= nil then
						return c.accept()
					end
					-- 单条候选 → 自动确认
					local items = c.get_items()
					if items and #items == 1 then
						return c.accept({ index = 1 })
					end
					return nil
				end,
				"fallback",
			},
		},
	},
}
