local M = {
	"lewis6991/gitsigns.nvim",
}

function M.config()
	require("gitsigns").setup({
		attach_to_untracked = true,
		on_attach = function(bufnr)
			local function map(mode, l, r, opts)
				opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end
			require("configs.keymaps").gitsigns(map)
		end,
	})
end
return M
