return {
	"nvim-tree/nvim-tree.lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeOpen", "NvimTreeFindFile" },
	keys = {
		{ "<leader>ll", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
	},
	init = function()
		-- disable netrw early so nvim-tree fully takes over
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
	end,
	opts = {
		on_attach = function(bufnr)
			local api = require("nvim-tree.api")

			local function opt(desc)
				return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
			end

			local map = vim.keymap.set
			map("n", "<CR>", api.node.open.edit, opt("Open"))
			map("n", "<2-LeftMouse>", api.node.open.edit, opt("Open"))
			map("n", "<Tab>", api.node.open.preview, opt("Open Preview"))
			map("n", ".", api.tree.toggle_hidden_filter, opt("Toggle Dotfiles"))
			map("n", "i", api.tree.toggle_gitignore_filter, opt("Toggle Git Ignore"))
			map("n", "f", api.live_filter.start, opt("Filter"))
			map("n", "F", api.live_filter.clear, opt("Clean Filter"))
			map("n", "a", api.fs.create, opt("Create"))
			map("n", "d", api.fs.remove, opt("Delete"))
			map("n", "r", api.fs.rename, opt("Rename"))
			map("n", "x", api.fs.cut, opt("Cut"))
			map("n", "c", api.fs.copy.node, opt("Copy"))
			map("n", "p", api.fs.paste, opt("Paste"))
			map("n", "R", api.tree.reload, opt("Refresh"))
			map("n", "A", api.tree.expand_all, opt("Expand All"))
			map("n", "yn", api.fs.copy.filename, opt("Copy Name"))
			map("n", "yr", api.fs.copy.relative_path, opt("Copy Relative Path"))
			map("n", "ya", api.fs.copy.absolute_path, opt("Copy Absolute Path"))
		end,
		git = { enable = false },
		update_focused_file = {
			enable = true,
			update_cwd = true,
		},
		filters = {
			dotfiles = true,
			custom = { "node_modules", ".idea", "__pycache__" },
		},
		view = {
			width = 40,
			side = "left",
			number = false,
			relativenumber = false,
			signcolumn = "yes",
		},
		actions = {
			open_file = {
				resize_window = true,
				quit_on_open = true,
			},
		},
	},
}
