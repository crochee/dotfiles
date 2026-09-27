-- XDG session type decides IME backend: X11 → XIM, Wayland → zwp_text_input_v3.
local session_type = os.getenv("XDG_SESSION_TYPE") or ""
local platform = require("utils.platform")()

return {
	apply_to_config = function(config)
		config.use_ime = true
		-- xim_im_name is X11-only; Wayland goes through zwp_text_input_v3.
		if platform.is_linux and session_type ~= "wayland" then
			config.xim_im_name = "fcitx"
		end
		config.animation_fps = 60
		config.max_fps = 60

		config.front_end = "WebGpu"
		config.webgpu_power_preference = "HighPerformance"
		config.webgpu_preferred_adapter = require("utils.gpu_adapter"):pick_best()
		config.enable_wayland = session_type == "wayland"

		config.window_background_opacity = 1.0
		config.text_background_opacity = 1.0
		config.enable_scroll_bar = true
		config.scrollback_lines = 5000

		config.enable_tab_bar = true
		config.hide_tab_bar_if_only_one_tab = true
		config.use_fancy_tab_bar = false
		config.tab_max_width = 25
		config.show_tab_index_in_tab_bar = false
		config.switch_to_last_active_tab_when_closing_tab = true

		config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
		config.default_cursor_style = "BlinkingBar"
		config.window_padding = { left = 5, right = 10, top = 12, bottom = 7 }
		config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.65 }
		config.skip_close_confirmation_for_processes_named = {
			"bash", "sh", "zsh", "tmux",
			"cmd.exe", "pwsh.exe", "powershell.exe",
		}
		config.window_close_confirmation = "AlwaysPrompt"
		config.window_frame = { active_titlebar_bg = "#090909" }

		config.pane_focus_follows_mouse = true
	end,
}