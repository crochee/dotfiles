-- lua/configs/wezterm-osc.lua — publish nvim keymap claims via OSC 1337
-- (consumed by wezterm/config/bindings.lua dispatch()).
-- Vars:
--   IS_NVIM   = true|false      — UIEnter/VimResume/FocusGained → true; ...Pre/...Suspend/FocusLost → false.
--   NVIM_KEYS = "CTRL|\\,ALT|k,F7,..."  — current + buffer-local mappings
--                                    (re-emitted on BufWinEnter/FileType/LazyDone).
-- Sources: lazy.nvim spec.keys + nvim_get_keymap(MODES) + nvim_buf_get_keymap(MODES).
-- Normalization: mods sorted (CTRL|SHIFT|ALT|SUPER); single-char key lowercased; CR/Esc/Tab/Space/BS
-- via nvim_replace_termcodes (byte-equal to wezterm's single-char `key`); virtual keys
-- (Up/Down/...) pass through — wezterm's canon table handles its own naming.
-- tmux passthrough auto-wrapped (server needs `set -g allow-passthrough on`).

local M = {}

local MOD_ALIASES = { C = "CTRL", S = "SHIFT", A = "ALT", M = "ALT", D = "SUPER" }
local MOD_ORDER = { "CTRL", "SHIFT", "ALT", "SUPER" }
-- Public nvim mapping modes (:h maparg-modes); skip !/l/langmap.
local MODES = { "n", "i", "v", "x", "s", "o", "t", "c" }

function M.normalize(lhs)
	local body = lhs:match("^<(.+)>$")
	if not body then return nil end
	local mods, rest, has_mod = {}, body, false
	while true do
		local m = rest:match("^([CASMD])%-")
		if not m then break end
		mods[#mods + 1] = MOD_ALIASES[m]
		if m ~= "S" then has_mod = true end
		rest = rest:sub(3)
	end
	-- Key normalization: lowercase single char, byte-equal CR/Esc/Tab/Space/BS,
	-- virtual keys pass through.
	local key
	if #rest == 1 then
		key = rest:lower()
	elseif rest:match("^F%d+$") then
		key = rest:upper()
	elseif rest == "Space" then
		key = " "
	elseif rest == "BS" or rest == "Backspace" then
		-- nvim_replace_termcodes("<BS>") returns the internal 3-byte keycode (unexpanded);
		-- explicit \127 is byte-equal to wezterm's single-char `key`.
		key = "\127"
	else
		-- CR/Esc/Tab/NL collapse to one byte; virtual keys (Up/Down/...) pass through.
		local byte = vim.api.nvim_replace_termcodes("<" .. rest .. ">", true, false, true)
		key = (#byte == 1) and byte or rest
	end
	if not (has_mod or key:match("^F%d")) then return nil end
	local set = {}
	for _, m in ipairs(mods) do set[m] = true end
	local parts = {}
	for _, m in ipairs(MOD_ORDER) do
		if set[m] then
			parts[#parts + 1] = m
			set[m] = nil
		end
	end
	local prefix = #parts > 0 and (table.concat(parts, "|") .. "|") or ""
	return prefix .. key
end

-- 源 1: lazy.nvim 插件 spec 的 keys 字段 (含未加载插件声明)。
local function from_lazy_specs()
	local ok, conf = pcall(require, "lazy.core.config")
	if not ok or type(conf) ~= "table" or type(conf.plugins) ~= "table" then
		return {}
	end
	local out = {}
	for _, spec in pairs(conf.plugins) do
		for _, k in ipairs(spec.keys or {}) do
			local lhs = type(k) == "table" and k[1] or k
			if type(lhs) == "string" then
				local id = M.normalize(lhs)
				if id then out[#out + 1] = id end
			end
		end
	end
	return out
end

-- 三源合并去重, 返回集合 (导出便于独立测试)。
function M.collect()
	local seen = {}
	for _, id in ipairs(from_lazy_specs()) do seen[id] = true end
	for _, mode in ipairs(MODES) do
		for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
			if map.lhs then
				local id = M.normalize(map.lhs)
				if id then seen[id] = true end
			end
		end
		for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
			if map.lhs then
				local id = M.normalize(map.lhs)
				if id then seen[id] = true end
			end
		end
	end
	return seen
end

-- Set → sorted, dedup'd, comma-joined string (dispatch's comparison form).
function M.compute()
	local list = {}
	for id in pairs(M.collect()) do list[#list + 1] = id end
	table.sort(list)
	return table.concat(list, ",")
end

-- Emit one OSC 1337 SetUserVar (base64-encoded value); wrap in tmux passthrough.
function M.emit(name, value)
	local seq = ("\027]1337;SetUserVar=%s=%s\007"):format(name, vim.base64.encode(value))
	if vim.env.TMUX then
		seq = "\027Ptmux;\027" .. seq .. "\027\\"
	end
	vim.api.nvim_out_write(seq)
end

local function publish(active)
	M.emit("IS_NVIM", active and "true" or "false")
	M.emit("NVIM_KEYS", active and M.compute() or "")
end

function M.setup()
	-- Only emit in wezterm (incl. wezterm-behind-tmux). Other terminals would see
	-- bare ESC ]1337;…BEL in stdout (e.g. `nvim --headless … > file`).
	if vim.env.TERM_PROGRAM ~= "WezTerm"
		and not vim.env.WEZTERM_PANE
		and not vim.env.TMUX then
		return
	end

	local group = vim.api.nvim_create_augroup("user_wezterm_osc", { clear = true })
	-- Merge `extra` into the autocmd opts.
	local function on(events, fn, extra)
		local opts = vim.tbl_extend("force", { group = group, callback = fn }, extra or {})
		vim.api.nvim_create_autocmd(events, opts)
	end
	on({ "UIEnter", "VimResume", "FocusGained" }, function() publish(true) end)
	on({ "VimLeavePre", "VimSuspend", "FocusLost" }, function() publish(false) end)
	on({ "BufWinEnter", "FileType" }, function() M.emit("NVIM_KEYS", M.compute()) end)
	on({ "User" }, function() M.emit("NVIM_KEYS", M.compute()) end, { pattern = "LazyDone" })
end

return M
