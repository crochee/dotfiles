-- events/tab-title.lua — per-tab title with process / icon badges.
--
-- Lazy registration: only wire format-tab-title once per process. wezterm.on
-- accumulates handlers without dedup, so without this flag the renderer would
-- fire N times after N reloads.

local wezterm = require("wezterm")
local Cells = require("utils.cells")

local nf = wezterm.nerdfonts
local bold = Cells.bold

local GLYPH_SCIRCLE_LEFT = nf.ple_left_half_circle_thick
local GLYPH_SCIRCLE_RIGHT = nf.ple_right_half_circle_thick
local GLYPH_CIRCLE = nf.fa_circle
local GLYPH_ADMIN = nf.md_shield_half_full
local GLYPH_LINUX = nf.cod_terminal_linux
local GLYPH_DEBUG = nf.fa_bug
local GLYPH_SEARCH = nf.fa_search
local GLYPH_SSH = nf.md_ssh

local TITLE_INSET = { DEFAULT = 6, ICON = 8 }

local colors = {
	text_default          = { bg = "#45475A", fg = "#1C1B19" },
	text_hover            = { bg = "#587D8C", fg = "#1C1B19" },
	text_active           = { bg = "#7FB4CA", fg = "#11111B" },

	ssh_default           = { bg = "#45475A", fg = "#F38BA8" },
	ssh_hover             = { bg = "#587D8C", fg = "#F38BA8" },
	ssh_active            = { bg = "#7FB4CA", fg = "#F38BA8" },

	unseen_output_default = { bg = "#45475A", fg = "#FFA066" },
	unseen_output_hover   = { bg = "#587D8C", fg = "#FFA066" },
	unseen_output_active  = { bg = "#7FB4CA", fg = "#FFA066" },

	scircle_default       = { bg = "rgba(0, 0, 0, 0.4)", fg = "#45475A" },
	scircle_hover         = { bg = "rgba(0, 0, 0, 0.4)", fg = "#587D8C" },
	scircle_active        = { bg = "rgba(0, 0, 0, 0.4)", fg = "#7FB4CA" },
}

local function clean_process_name(proc)
	local name = proc:gsub("(.*[/\\])(.*)", "%2"):gsub("%.exe$", "")
	return name
end

local function create_title(process_name, base_title, max_width, inset)
	local title
	if process_name ~= "" then
		title = process_name
		if base_title ~= "wezterm" then
			-- Space between process badge and title; without it adjacent tabs visually merge.
			title = title .. " " .. base_title
		end
	else
		title = base_title
	end

	if base_title == "Debug" then
		title = GLYPH_DEBUG .. " DEBUG"
		inset = inset - 2
	end
	if base_title:match("^InputSelector:") then
		title = base_title:gsub("InputSelector:", GLYPH_SEARCH)
		inset = inset - 2
	end

	if #title > max_width - inset then
		title = title:sub(1, max_width - inset)
	else
		title = title .. string.rep(" ", max_width - #title - inset)
	end
	return title
end

local Tab = {}
Tab.__index = Tab

function Tab.new()
	return setmetatable({
		title = "",
		cells = Cells.new(),
		is_wsl = false,
		is_admin = false,
		is_ssh = false,
		unseen_output = false,
	}, Tab)
end

function Tab:set_info(pane, max_width)
	local process_name = clean_process_name(pane.foreground_process_name)
	self.is_wsl = process_name:match("^wsl") ~= nil
	self.is_admin = pane.title:match("^Administrator: ") ~= nil
			or pane.title:match("%(Admin%)") ~= nil
	self.is_ssh = pane.domain_name:match("^SSH") ~= nil
	self.unseen_output = pane.has_unseen_output

	if self.is_ssh then
		process_name = pane.domain_name:gsub("^SSH:(.*)", "%1")
	end

	local inset = (self.is_admin or self.is_wsl or self.is_ssh)
		and TITLE_INSET.ICON or TITLE_INSET.DEFAULT
	if self.unseen_output then inset = inset + 2 end

	self.title = create_title(process_name, pane.title, max_width, inset)
end

function Tab:set_cells()
	self.cells
		:add("scircle_left", GLYPH_SCIRCLE_LEFT)
		:add("admin",        " " .. GLYPH_ADMIN)
		:add("wsl",          " " .. GLYPH_LINUX)
		:add("ssh",          " " .. GLYPH_SSH)
		:add("title",        " ", nil, bold())
		:add("unseen_output"," " .. GLYPH_CIRCLE)
		:add("padding",      " ")
		:add("scircle_right", GLYPH_SCIRCLE_RIGHT)
end

function Tab:update_colors(tab_state)
	self.cells:set_text("title", " " .. self.title)
	self.cells:set_colors("scircle_left", colors["scircle_" .. tab_state])
	self.cells:set_colors("admin",        colors["text_" .. tab_state])
	self.cells:set_colors("wsl",          colors["text_" .. tab_state])
	self.cells:set_colors("ssh",          colors["ssh_" .. tab_state])
	self.cells:set_colors("title",        colors["text_" .. tab_state])
	self.cells:set_colors("unseen_output",colors["unseen_output_" .. tab_state])
	self.cells:set_colors("padding",      colors["text_" .. tab_state])
	self.cells:set_colors("scircle_right",colors["scircle_" .. tab_state])
end

local RENDER_VARIANTS = {
	{ "scircle_left", "title",        "padding", "scircle_right" },
	{ "scircle_left", "title",        "unseen_output", "padding", "scircle_right" },
	{ "scircle_left", "admin",        "title", "padding", "scircle_right" },
	{ "scircle_left", "admin",        "title", "unseen_output", "padding", "scircle_right" },
	{ "scircle_left", "wsl",          "title", "padding", "scircle_right" },
	{ "scircle_left", "wsl",          "title", "unseen_output", "padding", "scircle_right" },
	{ "scircle_left", "ssh",          "title", "padding", "scircle_right" },
	{ "scircle_left", "ssh",          "title", "unseen_output", "padding", "scircle_right" },
}

function Tab:render()
	local variant_idx
	if self.is_ssh then
		variant_idx = 7
	elseif self.is_wsl then
		variant_idx = 5
	elseif self.is_admin then
		variant_idx = 3
	else
		variant_idx = 1
	end
	if self.unseen_output then variant_idx = variant_idx + 1 end
	return self.cells:render(RENDER_VARIANTS[variant_idx])
end

local tab_list = {}
local M = {}

M.setup = function()
	if M._registered then return end
	M._registered = true

	wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, hover, max_width)
		local entry = tab_list[tab.tab_id]
		if not entry then
			entry = Tab.new()
			entry:set_info(tab.active_pane, max_width)
			entry:set_cells()
			tab_list[tab.tab_id] = entry
		else
			entry:set_info(tab.active_pane, max_width)
			entry:update_colors(
				tab.is_active and "active" or hover and "hover" or "default"
			)
		end
		return entry:render()
	end)
end

return M