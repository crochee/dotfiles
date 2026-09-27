return {
	-- mini.pairs: auto-close brackets/quotes
	{
		"echasnovski/mini.pairs",
		event = "InsertEnter",
		opts = {
			mappings = {
				["("] = { action = "open", pair = "()", neigh_pattern = "^[^\\]" },
				["["] = { action = "open", pair = "[]", neigh_pattern = "^[^\\]" },
				["{"] = { action = "open", pair = "{}", neigh_pattern = "^[^\\]" },
				["'"] = { action = "closeopen", pair = "''", neigh_pattern = "^[^%a\\]", register = { cr = false } },
				['"'] = { action = "closeopen", pair = '""', neigh_pattern = "^[^\\]", register = { cr = false } },
				["`"] = { action = "closeopen", pair = "``", neigh_pattern = "^[^\\]", register = { cr = false } },
				["<"] = { action = "open", pair = "<>", neigh_pattern = "^[^\\>" .. "]" },
			},
		},
	},
	-- mini.surround: add/delete/replace surroundings
	{
		"echasnovski/mini.surround",
		event = "VeryLazy",
		opts = {
			mappings = {
				add = "gsa",
				delete = "gsd",
				find = "gsf",
				find_left = "gsF",
				highlight = "gsh",
				replace = "gsr",
				update = "gsu",
			},
		},
	},
	-- mini.ai: extended text-objects
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
	},
	-- mini.comment: comment toggling (replaces Comment.nvim)
	{
		"echasnovski/mini.comment",
		event = "VeryLazy",
		opts = {},
	},
	-- mini.move: Alt+h/j/k/l 移动当前行/选区 (替代手写 m .+1 键位, 保留 register/marks)
	{
		"echasnovski/mini.move",
		event = "VeryLazy",
		opts = {},
		-- mini.move 只建 normal/visual 映射；insert 模式的 Alt+j/k 在此补齐
		-- （旧行为: <esc><cmd>m .+1<cr>==gi）。
		config = function(_, opts)
			require("mini.move").setup(opts)
			local move = require("mini.move")
			vim.keymap.set("i", "<A-j>", function()
				move.move_line("down")
			end, { desc = "Move line down" })
			vim.keymap.set("i", "<A-k>", function()
				move.move_line("up")
			end, { desc = "Move line up" })
		end,
	},
}
