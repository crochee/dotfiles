-- lazy.nvim 精简配置：只保留与默认不同的部分

return {
	root = vim.fn.stdpath("data") .. "/lazy",
	defaults = {
		-- 未声明触发条件的 spec 按需加载（配合各 spec 的 event/keys/cmd/ft）
		lazy = true,
	},
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
	git = {
		url_format = "git@github.com:%s.git",
		timeout = 120,
		filter = true,
	},
	install = {
		missing = true,
		colorscheme = { "everforest", "habamax" },
	},
	checker = { enabled = false },
	-- 当前插件均不依赖 LuaRocks；关闭无效的 hererocks 探测
	rocks = {
		enabled = false,
	},
	performance = {
		cache = { enabled = true },
		reset_packpath = true,
		rtp = {
			reset = true,
			-- 仅留 netrwPlugin: nvim-tree.lua 接管文件树, 需让 netrw 不自动起.
			-- 其余 (gzip/matchit/matchparen/tarPlugin/zipPlugin/tohtml/tutor)
			-- nvim 0.10+ 已默认禁用, 列出来无意义.
			disabled_plugins = { "netrwPlugin" },
		},
	},
}
