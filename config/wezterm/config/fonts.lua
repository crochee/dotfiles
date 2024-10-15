local wezterm = require("wezterm")
local platform = require("utils.platform")

-- https://www.nerdfonts.com/font-downloads
return {
	-- color scheme
	color_scheme = "Catppuccin Macchiato (Gogh)",
	font_size = platform().is_mac and 24 or 22,
	line_height = 1.2,
	font = wezterm.font_with_fallback({
		{ family = "FantasqueSansM Nerd Font Mono", weight = "Bold", italic = true },
	}),
}
