-- events/right-status.lua — right status: cwd + hostname + date + battery.
-- Lazy registration (see events/tab-title.lua for the same pattern).
-- OSC 7 supplies cwd + remote host; wezterm handles ssh without extra config.

local wezterm = require("wezterm")

local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

local colors = {
	"#3c1361",
	"#52307c",
	"#663a82",
	"#7c5295",
	"#b491c8",
}
local text_fg = "#c0c0c0"

local function short_host(name)
	if name == "" then return "" end
	local dot = name:find("%.")
	return dot and name:sub(1, dot - 1) or name
end

local function cwd_and_host(pane)
	local cwd, hostname = "", ""

	-- Closing panes throw "pane id N not found in mux" — guard, render rest of the row.
	local ok, cwd_uri = pcall(function()
		return pane:get_current_working_dir()
	end)
	if not ok or not cwd_uri then return "", short_host(wezterm.hostname()) end

	if type(cwd_uri) == "userdata" then
		cwd = cwd_uri.file_path or ""
		hostname = short_host(cwd_uri.host or wezterm.hostname())
	else
		local s = cwd_uri:sub(8)
		local slash = s:find("/", 1, true)
		if slash then
			hostname = short_host(s:sub(1, slash - 1))
			cwd = s:sub(slash):gsub("%%(%x%x)", function(hex)
				return string.char(tonumber(hex, 16))
			end)
		end
	end

	if hostname == "" then hostname = short_host(wezterm.hostname()) end

	local home = wezterm.home_dir
	if cwd == home then
		cwd = "~"
	elseif cwd:sub(1, #home + 1) == home .. "/" then
		cwd = "~" .. cwd:sub(#home + 1)
	end

	return cwd, hostname
end

local M = {}

M.setup = function()
	if M._registered then return end
	M._registered = true

	wezterm.on("update-right-status", function(window, pane)
		local cells = {}
		local cwd, host = cwd_and_host(pane)
		if cwd ~= "" then table.insert(cells, cwd) end
		table.insert(cells, host)
		table.insert(cells, wezterm.strftime("%a %b %-d %H:%M"))

		for _, b in ipairs(wezterm.battery_info()) do
			table.insert(cells, string.format("%.0f%%", b.state_of_charge * 100))
		end

		local elements = {}
		local n = 0
		local function push(text, is_last)
			local bg = colors[(n % #colors) + 1]
			local next_bg = colors[((n + 1) % #colors) + 1]
			table.insert(elements, { Foreground = { Color = text_fg } })
			table.insert(elements, { Background = { Color = bg } })
			table.insert(elements, { Text = " " .. text .. " " })
			if not is_last then
				table.insert(elements, { Foreground = { Color = next_bg } })
				table.insert(elements, { Text = SOLID_LEFT_ARROW })
			end
			n = n + 1
		end

		while #cells > 0 do
			push(table.remove(cells, 1), #cells == 0)
		end

		window:set_right_status(wezterm.format(elements))
	end)
end

return M