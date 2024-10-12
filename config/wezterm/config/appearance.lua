return {
	use_ime = true,
	xim_im_name = "fcitx",
	animation_fps = 60,
	max_fps = 60,
	front_end = "WebGpu",
	webgpu_power_preference = "HighPerformance",
	webgpu_preferred_adapter = require("utils.gpu_adapter"):pick_best(),
	enable_wayland = os.getenv("XDG_SESSION_TYPE") == "wayland",

	-- background
	window_background_opacity = 1.0,
	text_background_opacity = 1.0,

	-- scrollbar
	enable_scroll_bar = true,

	-- tab bar
	enable_tab_bar = true,
	-- hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = false,
	tab_max_width = 25,
	show_tab_index_in_tab_bar = false,
	switch_to_last_active_tab_when_closing_tab = true,

	-- window
	window_decorations = "INTEGRATED_BUTTONS|RESIZE",
	default_cursor_style = "BlinkingBar",
	window_padding = {
		left = 5,
		right = 10,
		top = 12,
		bottom = 7,
	},
	window_close_confirmation = "NeverPrompt",
	window_frame = {
		active_titlebar_bg = "#090909",
	},

	inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.65,
	},
}
