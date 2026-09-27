-- Bootstrap lazy.nvim + 基础配置.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"git@github.com:folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- project.nvim still calls vim.lsp.buf_get_clients (removed in 0.13). Forward.
vim.lsp.buf_get_clients = function(opts)
	return vim.lsp.get_clients(opts or {})
end

require("configs.options")
require("configs.keymaps")
require("configs.autocmds")
require("configs.wezterm-osc").setup()

require("lazy").setup({
	"folke/lazy.nvim",
	{ import = "plugins" },
}, require("configs.lazynvim"))