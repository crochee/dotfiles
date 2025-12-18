local wezterm = require("wezterm")
local platform = require("utils.platform")()
local M = {}

if platform.is_mac then
	M.mod = "SUPER"
elseif platform.is_win or platform.is_linux then
	M.mod = "CTRL"
end
M.re_mod = "SHIFT|" .. M.mod

function M.smart_split(mods, key)
	local event = "SmartSplit"
	wezterm.on(event, function(window, pane)
		local dim = pane:get_dimensions()
		if dim.pixel_height > dim.pixel_width then
			window:perform_action(wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
		else
			window:perform_action(wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }), pane)
		end
	end)
	return {
		key = key,
		mods = mods,
		action = wezterm.action.EmitEvent(event),
	}
end

function M.quick_select_with_prefix(mods, key)
	local event = "QuickSelectWithPrefix"
	wezterm.on(event, function(window, pane)
		window:perform_action(
			wezterm.action.PromptInputLine({
				action = wezterm.action_callback(function(win, p, line)
					if not line then
						return
					end
					wezterm.log_info("select with prefix: " .. line)
					win:perform_action(
						wezterm.action.QuickSelectArgs({
							patterns = { line .. "\\S*" },
						}),
						p
					)
				end),
				description = "quick select with prefix:",
			}),
			pane
		)
	end)
	return {
		key = key,
		mods = mods,
		action = wezterm.action.EmitEvent(event),
	}
end

function M.open_file_with_browser(mods, key)
	local event = "OpenWithBrowser"
	wezterm.on(event, function(window, pane)
		window:perform_action(
			wezterm.action.PromptInputLine({
				action = wezterm.action_callback(function(_, _, line)
					if not line then
						return
					end
					if wezterm.target_triple == "x86_64-pc-windows-msvc" then
						line = "/wsl.localhost/Arch" .. line
					end
					line = "file:/" .. line
					wezterm.log_info("opening: " .. line)
					wezterm.open_with(line)
				end),
				description = "open with browser:",
			}),
			pane
		)
	end)
	return {
		key = key,
		mods = mods,
		action = wezterm.action.EmitEvent(event),
	}
end

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

local BW_CACHE

function M.fill_password(mods, key)
	-- 定义 WSL 执行函数（适配 crochee 用户）
	local function wsl_crochee_command(command)
		-- 基础命令
		local args = {
			"wsl",
			"-u",
			"crochee", -- 指定用户
			"--cd",
			"~", -- 启动目录
			"--", -- 分隔参数
		}
		-- 添加目标命令
		for _, arg in ipairs(command) do
			table.insert(args, arg)
		end
		-- 执行并返回结果
		return wezterm.run_child_process(args)
	end
	-- 安全获取密码的函数（通过 WSL 中的 bw CLI）
	local function get_bw_items()
		if BW_CACHE then
			return BW_CACHE
		end
		local success, stdout, stderr = wsl_crochee_command({
			"~/.local/bin/bw",
			"unlock",
			"--passwordfile",
			"~/.mp.txt",
			"--raw",
		})
		if not success then
			return nil, stderr
		end
		success, stdout, stderr = wsl_crochee_command({
			"~/.local/bin/bw",
			"--raw",
			"--session",
			stdout:gsub("%s+", ""),
			"list",
			"items",
		})
		if success then
			BW_CACHE = wezterm.json_parse(stdout)
			return BW_CACHE
		else
			return nil, stderr
		end
	end
	local event = "fill-password"
	wezterm.on(event, function(window, pane)
		local items, err = get_bw_items()
		if items then
			local choices = {}
			for _, item in pairs(items) do
				table.insert(choices, { label = item.name, id = item.login.password })
			end
			window:perform_action(
				wezterm.action.InputSelector({
					title = "Select password",
					fuzzy = true,
					fuzzy_description = "Fuzzy search:",
					choices = choices,
					action = wezterm.action_callback(function(_, _, id, label)
						wezterm.log_info("selected" .. label .. " password: " .. id)
						if id then
							pane:send_text(id)
							pane:send_text("\n") -- 可选：自动提交
						end
					end),
				}),
				pane
			)
		else
			window:toast_notification("bitwarden", "Failed to get password.\n\n" .. wezterm.to_string(err), nil, 4000)
		end
	end)
	return {
		key = key,
		mods = mods,
		action = wezterm.action.EmitEvent(event),
	}
end

return {
	keys = {
		-- misc/useful --
		{ key = "F3", mods = "NONE", action = wezterm.action.ShowLauncher },
		{ key = "F4", mods = "NONE", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },
		{
			key = "F5",
			mods = "NONE",
			action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
		},
		{
			key = "Enter",
			mods = M.re_mod,
			action = wezterm.action.CloseCurrentPane({ confirm = false }),
		},
		M.smart_split(M.mod, "Enter"),
		{
			key = ";",
			mods = M.mod,
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
		M.quick_select_with_prefix(M.mod, "/"),
		M.open_file_with_browser(M.mod, "'"),
		-- resize and move
		M.split_nav("resize", M.mod, "LeftArrow", "Right"),
		M.split_nav("resize", M.mod, "RightArrow", "Left"),
		M.split_nav("resize", M.mod, "UpArrow", "Up"),
		M.split_nav("resize", M.mod, "DownArrow", "Down"),
		-- custom
		M.fill_password(M.mod, "p"),
		{
			key = "F6",
			mods = "NONE",
			action = wezterm.action.SendString(
				"kubectl exec -it -n openstack  $(kubectl get pods -n openstack | grep mariadb| grep server | grep Running | awk '{print $1}') -- mysql --defaults-file=/etc/mysql/admin_user.cnf"
			),
		},
	},
}
