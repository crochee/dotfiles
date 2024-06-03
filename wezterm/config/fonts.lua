local wezterm = require('wezterm')
local platform = require('utils.platform')


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

return {
  -- color scheme
  color_scheme = 'Catppuccin Macchiato (Gogh)',

  font_size = platform().is_mac and 20 or 18,
  line_height = 1.2,
  font = wezterm.font('FantasqueSansM Nerd Font Mono', { weight = 'Bold', italic = true }),

}
