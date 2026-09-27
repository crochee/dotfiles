-- config/fonts.lua — color scheme, sizing, and font.
--
-- Color scheme and font sizing live here because they are the visual
-- knobs most likely to change without touching the rest of appearance.
-- Renderer/WebGPU/IME settings live in appearance.lua.
--
-- wezterm 内置全部 Nerd Font PUA glyph (ple_*, fa_*, md_*, cod_*, dev_*, seti_*),
-- 任何主字体都能渲染 — 不需要 font_fallback 配置. 主字体覆盖 PUA codepoints
-- 时改用 config.font = wezterm.font_with_fallback(...).

local wezterm = require("wezterm")
local platform = require("utils.platform")()

return {
	apply_to_config = function(config)
		config.color_scheme = "Catppuccin Macchiato (Gogh)"
		config.font_size = platform.is_mac and 24 or 22
		config.line_height = 1.2

		-- 主字体: JetBrains Mono Nerd Font (含 Nerd Font PUA + Latin/CJK).
		-- 缺失时 wezterm 内置 Nerd Font 渲染兜底, 不会出方块.
		config.font = wezterm.font("JetBrainsMono Nerd Font")
	end,
}