-- Pull in the wezterm API
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
-- This is where you actually apply your config choices
require("links").setup(config)
require("keys").setup(config)

local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark'
end

local function theme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'Molokai'
  else
    return 'Catppuccin Macchiato (Gogh)'
  end
end

local function default_prog()
  if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    return { 'wsl', '~' }
  end
  return { 'bash' }
end

wezterm.on('user-var-changed', function(window, pane, name, value)
  local overrides = window:get_config_overrides() or {}
  if name == "ZEN_MODE" then
    local incremental = value:find("+")
    local number_value = tonumber(value)
    if incremental ~= nil then
      while (number_value > 0) do
        window:perform_action(wezterm.action.IncreaseFontSize, pane)
        number_value = number_value - 1
      end
      overrides.enable_tab_bar = false
    elseif number_value < 0 then
      window:perform_action(wezterm.action.ResetFontSize, pane)
      overrides.font_size = nil
      overrides.enable_tab_bar = true
    else
      overrides.font_size = number_value
      overrides.enable_tab_bar = false
    end
  end
  window:set_config_overrides(overrides)
end)

-- and finally, return the configuration to wezterm
config.enable_wayland = true
config.default_prog = default_prog()
config.window_close_confirmation = "NeverPrompt"
-- config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

-- This is where you actually apply your config choices
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.8,
}

config.window_background_opacity = 1.0
-- config.window_background_image = "./img.jpeg"
config.text_background_opacity = 1.0
-- color_scheme
config.color_scheme = theme_for_appearance(get_appearance())
-- cursor
config.default_cursor_style = "BlinkingBar"
config.window_padding = {
  top = "1cell",
  right = "3cell",
  bottom = "1cell",
  left = "3cell",
}
-- font
config.font_size = 18
config.line_height = 1.2
config.font = wezterm.font('FantasqueSansM Nerd Font Mono', { weight = 'Bold', italic = true })
config.window_frame = {
  font = wezterm.font { family = "Recursive Sans Linear Static", weight = "Medium" },
}

config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

return config
