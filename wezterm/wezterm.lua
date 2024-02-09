-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This is where you actually apply your config choices

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
    -- Spawn a fish shell in login mode
    -- return { 'ubuntu.exe' }
    return { 'wsl', '~' }
  end
  -- return { 'tmux' }
  return { 'bash' }
end

-- and finally, return the configuration to wezterm
return {
  enable_wayland = true,
  color_scheme = theme_for_appearance(get_appearance()),

  font_size = 18,
  line_height = 1.2,
  font = wezterm.font('FantasqueSansM Nerd Font Mono', { weight = 'Bold', italic = true }),
  default_cursor_style = "BlinkingBar",

  default_prog = default_prog(),
  window_close_confirmation = "NeverPrompt",
  window_decorations = "RESIZE",
  hide_tab_bar_if_only_one_tab = true,

  window_padding = {
    top = "1cell",
    right = "3cell",
    bottom = "1cell",
    left = "3cell",
  },
  window_frame = {
    font = wezterm.font { family = "Recursive Sans Linear Static", weight = "Medium" },
  },
  -- This is where you actually apply your config choices
  -- window_background_opacity = 0.5,
  -- window_background_image = "./img.jpeg",

  inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.8,
  },

  window_background_opacity = 1.0,
  text_background_opacity = 1.0,
}
