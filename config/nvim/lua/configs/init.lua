-- 插件安装目录
-- ~/.local/share/nvim/lazy/lazy.nvim
-- 自动安装 Lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"git@github.com:folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("configs.options")
require("configs.keymaps")
require("configs.autocmds")
local opts = require("configs.lazynvim")

require("lazy").setup({
	-- Lazy can manage itself
	"folke/lazy.nvim",

	-- import/override with your plugins
	{ import = "plugins" },
}, opts)
