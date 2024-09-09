return {
	"nvimdev/dashboard-nvim",
	dependencies = { { "nvim-tree/nvim-web-devicons", "echasnovski/mini.icons" } },
	config = function()
		-- local home = os.getenv("HOME")
		require("dashboard").setup({
			-- theme: hyper, doom
			theme = "hyper",
			config = {
				week_header = { enable = true },
				packages = { enable = true }, -- show how many plugins neovim loaded
				-- limit how many projects list, action when you press key or enter it will run this action.
				project = {
					enable = false,
					limit = 8,
					action = "Telescope find_files cwd=",
				},
				footer = { "", "岂能尽如人意，但求无愧我心" },
				shortcut = {
					{
						desc = " Update",
						group = "@property",
						action = "Lazy update",
						key = "u",
					},
					{
						desc = " Files",
						group = "Label",
						action = "Telescope find_files",
						key = "f",
					},
					{
						desc = " dotfiles",
						group = "Number",
						action = "Telescope find_files cwd=~/.config/nvim",
						key = "d",
					},
				},
			},
		})
	end,
}
