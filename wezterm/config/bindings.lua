local wezterm = require("wezterm")
local platform = require('utils.platform')()
local act = wezterm.action

local M = {}

if platform.is_mac then
  M.mod = 'SHIFT|SUPER'
elseif platform.is_win or platform.is_linux then
  M.mod = 'SHIFT|CTRL'
end

M.smart_split = wezterm.action_callback(function(window, pane)
  local dim = pane:get_dimensions()
  if dim.pixel_height > dim.pixel_width then
    window:perform_action(act.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
  else
    window:perform_action(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), pane)
  end
end)

M.close_pane = wezterm.action_callback(function(window, pane)
  window:perform_action(act.CloseCurrentPane({ confirm = false }), pane)
end)

---@param resize_or_move "resize" | "move"
---@param mods string
---@param key string
---@param dir "Right" | "Left" | "Up" | "Down"
function M.split_nav(resize_or_move, mods, key, dir)
  local event = "SplitNav_" .. resize_or_move .. "_" .. dir
  wezterm.on(event, function(win, pane)
    if M.is_nvim(pane) then
      -- pass the keys through to vim/nvim
      win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
    else
      if resize_or_move == "resize" then
        win:perform_action({ AdjustPaneSize = { dir, 3 } }, pane)
      else
        local panes = pane:tab():panes_with_info()
        local is_zoomed = false
        for _, p in ipairs(panes) do
          if p.is_zoomed then
            is_zoomed = true
          end
        end
        wezterm.log_info("is_zoomed: " .. tostring(is_zoomed))
        if is_zoomed then
          dir = dir == "Up" or dir == "Right" and "Next" or "Prev"
          wezterm.log_info("dir: " .. dir)
        end
        win:perform_action({ ActivatePaneDirection = dir }, pane)
        win:perform_action({ SetPaneZoomState = is_zoomed }, pane)
      end
    end
  end)
  return {
    key = key,
    mods = mods,
    action = wezterm.action.EmitEvent(event),
  }
end

function M.is_nvim(pane)
  return pane:get_user_vars().IS_NVIM == "true" or pane:get_foreground_process_name():find("n?vim")
end

return {
  leader = { key = 'a', mods = M.mod },
  keys = {
    -- misc/useful --
    { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
    { key = 'F4', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
    {
      key = 'F5',
      mods = 'NONE',
      action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }),
    },
    { mods = M.mod, key = "Enter", action = M.smart_split },
    { mods = M.mod, key = "q",     action = M.close_pane },
    {
      key = 'u',
      mods = M.mod,
      action = wezterm.action.QuickSelectArgs({
        label = 'open url',
        patterns = {
          '\\((https?://\\S+)\\)',
          '\\[(https?://\\S+)\\]',
          '\\{(https?://\\S+)\\}',
          '<(https?://\\S+)>',
          '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
        },
        action = wezterm.action_callback(function(window, pane)
          local url = window:get_selection_text_for_pane(pane)
          wezterm.log_info('opening: ' .. url)
          wezterm.open_with(url)
        end),
      }),
    },
    -- resize and move
    M.split_nav("resize", "CTRL", "LeftArrow", "Right"),
    M.split_nav("resize", "CTRL", "RightArrow", "Left"),
    M.split_nav("resize", "CTRL", "UpArrow", "Up"),
    M.split_nav("resize", "CTRL", "DownArrow", "Down"),
  },
}
