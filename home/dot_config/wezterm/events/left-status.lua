-- events/left-status.lua — left status: active key table indicator.
-- wezterm rebuilds Lua state on reload; module-level flag prevents double setup().

local wezterm = require("wezterm")
local Cells = require("utils.cells")
local nf = wezterm.nerdfonts

local GLYPH_SCIRCLE_LEFT = nf.ple_left_half_circle_thick
local GLYPH_SCIRCLE_RIGHT = nf.ple_right_half_circle_thick
local GLYPH_KEY_TABLE = nf.md_table_key

local colors = {
	default = { bg = "#fab387", fg = "#1c1b19" },
	scircle = { bg = "rgba(0, 0, 0, 0.4)", fg = "#fab387" },
}

local cells = Cells.new()
cells
	:add(1, GLYPH_SCIRCLE_LEFT, colors.scircle, Cells.bold())
	:add(2, " ", colors.default, Cells.bold())
	:add(3, " ", colors.default, Cells.bold())
	:add(4, GLYPH_SCIRCLE_RIGHT, colors.scircle, Cells.bold())

local M = {}

M.setup = function()
	if M._registered then return end
	M._registered = true

	wezterm.on("update-status", function(window, _pane)
		local name = window:active_key_table()
		if name then
			cells:set_text(2, GLYPH_KEY_TABLE):set_text(3, " " .. string.upper(name))
		else
			window:set_left_status("")
			return
		end
		window:set_left_status(wezterm.format(cells:render_all()))
	end)
end

return M