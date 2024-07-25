local M = {
	"akinsho/toggleterm.nvim",
}
function M.config()
	local status, toggleterm = pcall(require, "toggleterm")
	if not status then
		vim.notify("没有找到 toggleterm")
		return
	end

	toggleterm.setup({
		open_mapping = [[<C-\>]],
		hide_numbers = true,
		shade_filetypes = {},
		shade_terminals = true,
		shading_factor = 2,
		start_in_insert = true,
		insert_mappings = true,
		persist_size = true,
		direction = "float",
		close_on_exit = true,
		on_open = function(term)
			vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
		end,
		shell = vim.o.shell,
		float_opts = {
			border = "double", -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
			winblend = 3,
			highlights = {
				border = "Normal",
				background = "Normal",
			},
		},
		winbar = {
			enabled = true,
			name_formatter = function(term) --  term: Terminal
				return term.name
			end,
		},
	})

	-- local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })
	function _LAZYGIT_OPEN(opts)
		opts = vim.tbl_deep_extend("force", {}, opts or {})

		local cmd = { "lazygit" }
		vim.list_extend(cmd, opts.args or {})

		require("toggleterm.terminal").Terminal
			:new({
				id = 1000, --[[ 解决lazygit关闭通用窗口问题 ]]
				dir = "git_dir",
				float_opts = {
					border = "curved", -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
				},
				cmd = table.concat(cmd, " "),
			})
			:toggle()
	end
end

return M
