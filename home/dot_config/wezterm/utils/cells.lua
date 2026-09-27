-- utils/cells.lua — small FormatItem builder for wezterm.format().
--
-- Used by events/tab-title.lua and events/left-status.lua to compose
-- status-bar segments: both build several segments with state-driven
-- color updates, and inlining would duplicate the prepend/append logic.
--
-- API:
--   cells = Cells.new()
--   cells:add(id, text, color?, attr?)        -- attr is one item, not a list
--   cells:set_text(id, text)                   -- update text in place
--   cells:set_colors(id, color)                -- update bg/fg in place
--   cells:render(ids) -> FormatItem[]
--   cells:render_all() -> FormatItem[]

local M = {}
M.__index = M

function M.new()
	return setmetatable({ segments = {} }, M)
end

local function build_items(text, color, attr)
	local items = {}
	color = color or {}
	if color.bg then table.insert(items, { Background = { Color = color.bg } }) end
	if color.fg then table.insert(items, { Foreground = { Color = color.fg } }) end
	if attr then table.insert(items, attr) end
	table.insert(items, { Text = text })
	table.insert(items, "ResetAttributes")
	return items
end

function M:add(id, text, color, attr)
	self.segments[id] = { items = build_items(text, color, attr) }
	return self
end

function M:set_text(id, text)
	local seg = self.segments[id]
	assert(seg, "segment not found: " .. tostring(id))
	-- items layout: [bg?] [fg?] [attr?] Text ResetAttributes
	-- text is the second-to-last item.
	seg.items[#seg.items - 1] = { Text = text }
	return self
end

function M:set_colors(id, color)
	local seg = self.segments[id]
	assert(seg, "segment not found: " .. tostring(id))
	assert(type(color) == "table", "color must be a table")
	-- Rebuild preserving the optional attr item at its position.
	-- Find existing attr by scanning for an item with .Attribute.
	local attr = nil
	for _, it in ipairs(seg.items) do
		if it.Attribute then attr = it break end
	end
	self.segments[id] = { items = build_items(
		-- current text: scan for the Text item
		(function()
			for _, it in ipairs(seg.items) do
				if it.Text then return it.Text end
			end
			return ""
		end)(),
		color,
		attr
	) }
	return self
end

function M:render(ids)
	local out = {}
	for _, id in ipairs(ids) do
		assert(self.segments[id], "segment not found: " .. tostring(id))
		for _, item in ipairs(self.segments[id].items) do
			table.insert(out, item)
		end
	end
	return out
end

function M:render_all()
	local out = {}
	for _, seg in pairs(self.segments) do
		for _, item in ipairs(seg.items) do
			table.insert(out, item)
		end
	end
	return out
end

-- Attribute builder. Returns one item, ready to pass as the 4th arg to :add().
M.bold = function() return { Attribute = { Intensity = "Bold" } } end

return M