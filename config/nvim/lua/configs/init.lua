-- Bootstrap lazy.nvim + 基础配置
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

-- 个别插件仍调用已移除的 vim.lsp.buf_get_clients（nvim 0.11+）
vim.lsp.buf_get_clients = function(opts)
	return vim.lsp.get_clients(opts or {})
end
-- 未使用的可选远程提供者不应参与健康检查
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

require("configs.options")
require("configs.keymaps")
require("configs.autocmds") -- 含 vim.lsp.enable + LspAttach 键位

require("lazy").setup({
	"folke/lazy.nvim",
	{ import = "plugins" },
}, require("configs.lazynvim"))
