-- config/bindings.lua — cross-platform keys. Authority: docs/KEYMAP.md.
--
-- mod = SUPER (macOS) | CTRL (Linux/Windows); re_mod = SHIFT|mod.
-- Dispatch order: nvim (OSC 1337 → NVIM_KEYS) → omp (static claim) → wezterm.
-- NVIM_FALLBACK covers tmux without allow-passthrough.

local wezterm = require("wezterm")
local platform = require("utils.platform")()

local mod    = platform.is_mac and "SUPER" or "CTRL"
local re_mod = "SHIFT|" .. mod

local function is_nvim(pane)
	if pane:get_user_vars().IS_NVIM == "true" then return true end
	local name = pane:get_foreground_process_name()
	return name ~= nil and name:find("n?vim") ~= nil
end

local function is_omp(pane)
	local name = pane:get_foreground_process_name()
	return name ~= nil
		and (name:match("[/\\]omp$") ~= nil or name:match("[/\\]omp%.exe$") ~= nil)
end

-- Canonicalize a chord: mods sorted (CTRL|SHIFT|ALT|SUPER), single-char key lowercased,
-- F<N> uppercased, virtual keys mapped to wezterm names.
local CANON_NAMED = {
	left = "LeftArrow", right = "RightArrow", up = "UpArrow", down = "DownArrow",
	home = "Home", end_ = "End",
	pageup = "PageUp", pagedown = "PageDown",
	insert = "Insert", delete = "Delete",
}
local function canon(key, mods)
	local set = {}
	if mods and mods ~= "NONE" then
		for m in mods:gmatch("[^|]+") do set[m] = true end
	end
	local parts = {}
	for _, m in ipairs({ "CTRL", "SHIFT", "ALT", "SUPER" }) do
		if set[m] then
			parts[#parts + 1] = m
			set[m] = nil
		end
	end
	for m in pairs(set) do parts[#parts + 1] = m end
	local k
	if #key == 1 then
		k = key:lower()
	elseif key:match("^F%d+$") then
		k = key:upper()
	else
		k = CANON_NAMED[key:lower()] or key
	end
	local prefix = #parts > 0 and (table.concat(parts, "|") .. "|") or ""
	return prefix .. k
end

local OMP_CLAIMS = {}
for _, k in ipairs({ "p", "r", "o", "t", "g", "q", "v", "l", "\r" }) do
	OMP_CLAIMS[canon(k, "CTRL")] = true
end
for _, k in ipairs({ "p", "o", "v", "r" }) do
	OMP_CLAIMS[canon(k, "CTRL|SHIFT")] = true
end
for _, k in ipairs({ "p", "m", "r", "l", "a", "v", "UpArrow" }) do
	OMP_CLAIMS[canon(k, "ALT")] = true
end
for _, k in ipairs({ "p", "l", "c", "v" }) do
	OMP_CLAIMS[canon(k, "ALT|SHIFT")] = true
end
OMP_CLAIMS[canon("Tab", "SHIFT")] = true
OMP_CLAIMS[canon("UpArrow", "SHIFT")] = true
OMP_CLAIMS[canon("DownArrow", "SHIFT")] = true

-- Fallback when NVIM_KEYS OSC var is unavailable (tmux without allow-passthrough).
local NVIM_FALLBACK = {}
for _, arrow in ipairs({ "LeftArrow", "RightArrow", "UpArrow", "DownArrow" }) do
	NVIM_FALLBACK[canon(arrow, mod)] = true
	NVIM_FALLBACK[canon(arrow, re_mod)] = true
end
NVIM_FALLBACK[canon("\r", mod)] = true

local function dispatch(key, mods, action)
	return wezterm.action_callback(function(window, pane)
		local id = canon(key, mods)
		local vars = pane:get_user_vars()
		if is_nvim(pane) then
			local exported = vars.NVIM_KEYS
			local claimed
			if exported and exported ~= "" then
				claimed = false
				for chunk in exported:gmatch("[^,]+") do
					-- greedy split so multi-mod chords (CTRL|SHIFT|LeftArrow) keep their mods.
					local m, k = chunk:match("^(.*)|(.+)$")
					if m and k then
						if canon(k, m) == id then claimed = true; break end
					elseif canon(chunk, "NONE") == id then
						claimed = true; break
					end
				end
			else
				claimed = NVIM_FALLBACK[id] ~= nil
			end
			if claimed then
				window:perform_action({ SendKey = { key = key, mods = mods } }, pane)
				return
			end
		end
		if is_omp(pane) and OMP_CLAIMS[id] then
			window:perform_action({ SendKey = { key = key, mods = mods } }, pane)
			return
		end
		window:perform_action(action, pane)
	end)
end

-- SmartSplit: vertical when window is taller than wide.
-- Ctrl+Enter is borrowed from omp followUp (omp has Ctrl+Q fallback).
local function on_smart_split(window, pane)
	local dim = pane:get_dimensions()
	if dim.pixel_height > dim.pixel_width then
		window:perform_action(wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
	else
		window:perform_action(wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }), pane)
	end
end

local function on_quick_select_with_prefix(window, pane)
	window:perform_action(
		wezterm.action.PromptInputLine({
			action = wezterm.action_callback(function(win, _p, line)
				if not line then return end
				wezterm.log_info("select with prefix: " .. line)
				win:perform_action(
					wezterm.action.QuickSelectArgs({ patterns = { line .. "\\S*" } })
				)
			end),
			description = "quick select with prefix:",
		}),
		pane
	)
end

-- Open a file:// URI. WSL detection runs in the callback (top-level
-- run_child_process can race config-load C boundaries). Cached in GLOBAL.
local WSL_DISTRO_KEY = "mod_open_wsl_distro"
local function resolve_wsl_distro()
	local cached = wezterm.GLOBAL.get_var and wezterm.GLOBAL.get_var(WSL_DISTRO_KEY)
	if cached and cached ~= "" then return cached end
	local v = os.getenv("WSL_DEFAULT_DISTRO")
	if not v or v == "" then
		-- wsl.exe prints UTF-16LE + optional banner; strip \0, drop the
		-- "Windows" line, take the token before "(" (e.g. "Arch (Default)" → "Arch").
		local ok, stdout = wezterm.run_child_process({ "wsl.exe", "-l", "--quiet" })
		if ok and stdout and stdout ~= "" then
			for line in stdout:gsub("\0", ""):gmatch("[^\r\n]+") do
				line = line:match("^%s*(.-)%s*$") or ""
				if line ~= "" and not line:find("Windows", 1, true) then
					v = (line:match("^[^(]+") or line):gsub("%s+$", "")
					break
				end
			end
		end
	end
	if v and v ~= "" and wezterm.GLOBAL.set_var then wezterm.GLOBAL.set_var(WSL_DISTRO_KEY, v) end
	return v or ""
end

local function on_open_with_browser(window, pane)
	window:perform_action(
		wezterm.action.PromptInputLine({
			action = wezterm.action_callback(function(_, _, line)
				if not line then return end
				if platform.is_win and line:sub(1, 1) == "/" then
					local distro = resolve_wsl_distro()
					if distro ~= "" then
						line = "/wsl.localhost/" .. distro .. line
					end
				end
				line = "file:/" .. line
				wezterm.log_info("opening: " .. line)
				wezterm.open_with(line)
			end),
			description = "open with browser:",
		}),
		pane
	)
end

-- Adjacent-pane focus that preserves the current zoom state.
local function on_split_nav_move(win, pane, dir)
	local panes = pane:tab():panes_with_info()
	local is_zoomed = false
	for _, p in ipairs(panes) do
		if p.is_zoomed then is_zoomed = true end
	end
	win:perform_action({ ActivatePaneDirection = dir }, pane)
	win:perform_action({ SetPaneZoomState = is_zoomed }, pane)
end

local RESIZE_KEYTABLE = "resize_mode"

-- Idempotent across reloads (wezterm.on accumulates handlers).
local function register_event_handlers()
	wezterm.on("SmartSplit", on_smart_split)
	wezterm.on("QuickSelectWithPrefix", on_quick_select_with_prefix)
	wezterm.on("OpenWithBrowser", on_open_with_browser)
	for _, dir in ipairs({ "Left", "Right", "Up", "Down" }) do
		wezterm.on("SplitNav_move_" .. dir, function(win, pane)
			on_split_nav_move(win, pane, dir)
		end)
	end
end

local M = {}

M.setup = function()
	if M._registered then return end
	M._registered = true
	register_event_handlers()
end

local DEFS = {
	{ key = "F3", mods = "NONE", action = wezterm.action.ShowLauncher },
	{ key = "F4", mods = "NONE", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },
	{ key = "F5", mods = "NONE", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = " ", mods = mod, action = wezterm.action.ShowLauncher },

	-- re_mod K = clear scrollback+viewport; ALT|SHIFT K = scrollback only.
	-- Not plain CTRL+K: readline owns it (kill to EOL).
	{ key = "k", mods = re_mod,      action = wezterm.action.ClearScrollback("ScrollbackAndViewport") },
	{ key = "k", mods = "ALT|SHIFT", action = wezterm.action.ClearScrollback("ScrollbackOnly") },

	{ key = " ", mods = re_mod, action = wezterm.action.QuickSelect },
	{ key = "x",     mods = re_mod, action = wezterm.action.ActivateCopyMode },
	-- PaneSelect on re_mod, not plain mod: CTRL+E is readline end-of-line.
	{ key = "e",     mods = re_mod, action = wezterm.action.PaneSelect },
	{
		key = ";", mods = mod,
		action = wezterm.action.QuickSelectArgs({
			label = "open url",
			patterns = {
				"\\((https?://\\S+)\\)",
				"\\[(https?://\\S+)\\]",
				"\\{(https?://\\S+)\\}",
				"<(https?://\\S+)>",
				"\\bhttps?://\\S+[)/a-zA-Z0-9-]+",
			},
			action = wezterm.action_callback(function(window, pane)
				local url = window:get_selection_text_for_pane(pane)
				wezterm.log_info("opening: " .. url)
				wezterm.open_with(url)
			end),
		}),
	},
	{ key = "/", mods = mod, action = wezterm.action.EmitEvent("QuickSelectWithPrefix") },
	{ key = "'", mods = mod, action = wezterm.action.EmitEvent("OpenWithBrowser") },

	{ key = "\r",       mods = re_mod, action = wezterm.action.CloseCurrentPane({ confirm = false }) },
	{ key = "\r",       mods = mod,    action = wezterm.action.EmitEvent("SmartSplit") },
	{ key = "LeftArrow",  mods = mod, action = wezterm.action.AdjustPaneSize({ "Left", 3 }) },
	{ key = "RightArrow", mods = mod, action = wezterm.action.AdjustPaneSize({ "Right", 3 }) },
	{ key = "UpArrow",    mods = mod, action = wezterm.action.AdjustPaneSize({ "Up", 3 }) },
	{ key = "DownArrow",  mods = mod, action = wezterm.action.AdjustPaneSize({ "Down", 3 }) },
	{ key = "LeftArrow",  mods = re_mod, action = wezterm.action.EmitEvent("SplitNav_move_Left") },
	{ key = "RightArrow", mods = re_mod, action = wezterm.action.EmitEvent("SplitNav_move_Right") },
	{ key = "UpArrow",    mods = re_mod, action = wezterm.action.EmitEvent("SplitNav_move_Up") },
	{ key = "DownArrow",  mods = re_mod, action = wezterm.action.EmitEvent("SplitNav_move_Down") },

	-- F7 enters resize_mode (arrows unmod; F-keys stay clear of Ctrl chords).
	{ key = "F7", mods = "NONE", action = { ActivateKeyTable = { name = RESIZE_KEYTABLE, one_shot = false } } },
}

return {
	apply_to_config = function(config)
		M.setup()

		config.keys = {}
		for _, d in ipairs(DEFS) do
			table.insert(config.keys, {
				key = d.key,
				mods = d.mods,
				action = dispatch(d.key, d.mods, d.action),
			})
		end

		config.key_tables = {
			[RESIZE_KEYTABLE] = {
				{ key = "LeftArrow",  mods = "NONE", action = wezterm.action.AdjustPaneSize({ "Left",  3 }) },
				{ key = "RightArrow", mods = "NONE", action = wezterm.action.AdjustPaneSize({ "Right", 3 }) },
				{ key = "UpArrow",    mods = "NONE", action = wezterm.action.AdjustPaneSize({ "Up",    3 }) },
				{ key = "DownArrow",  mods = "NONE", action = wezterm.action.AdjustPaneSize({ "Down",  3 }) },
				{ key = "x", mods = "NONE", action = "PopKeyTable" },
				{ key = "Escape", mods = "NONE", action = "PopKeyTable" },
			},
		}
	end,
}