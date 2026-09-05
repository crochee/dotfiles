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
}
