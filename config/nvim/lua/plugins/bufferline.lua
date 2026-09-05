return {
	"akinsho/bufferline.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	keys = {
		{ "<leader>q", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
		{ "<leader>w", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
		{ "<leader>cc", "<cmd>bd<cr>", desc = "Close current buffer" },
		{ "<leader>cr", "<cmd>BufferLineCloseRight<cr>", desc = "Close right buffers" },
		{ "<leader>cl", "<cmd>BufferLineCloseLeft<cr>", desc = "Close left buffers" },
		{ "<leader>co", "<cmd>BufferLineCloseRight<cr><cmd>BufferLineCloseLeft<cr>", desc = "Close other buffers" },
	},
	opts = {
		options = {
			diagnostics = "nvim_lsp",
			offsets = {
				{
					filetype = "NvimTree",
					text = "File Explorer",
					highlight = "Directory",
					text_align = "left",
				},
			},
		},
	},
}
