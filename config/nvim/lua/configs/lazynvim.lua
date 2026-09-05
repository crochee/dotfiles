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
	change_detection = { notify = false },
	performance = {
		cache = { enabled = true },
		reset_packpath = true,
		rtp = {
			reset = true,
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
}
