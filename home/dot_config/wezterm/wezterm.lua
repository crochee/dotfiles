-- wezterm.lua — 入口: 组装 config/ 下的模块并返回 config.
--
-- 每个 config/<name>.lua 导出 apply_to_config(config), 按下面的顺序调用;
-- events/ 下的模块导出 setup() 注册 wezterm.on() 处理器 (内部有幂等守卫).
-- 用内置的 wezterm.config_builder() (dedup-aware) 组装, 不再自建 Config:append.

local wezterm = require("wezterm")

-- 事件处理器先注册 (幂等 —— 各模块内部守卫)
require("events.left-status").setup()
require("events.right-status").setup()
require("events.tab-title").setup()

local config = wezterm.config_builder()

require("config.appearance").apply_to_config(config)
require("config.bindings").apply_to_config(config)
require("config.fonts").apply_to_config(config)
require("config.general").apply_to_config(config)
require("config.launch").apply_to_config(config)

return config
