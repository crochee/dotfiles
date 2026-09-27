-- config/launch.lua — default prog + launcher menu per OS.

local wezterm = require("wezterm")
local platform = require("utils.platform")()

local home = wezterm.home_dir

-- WSL default user ≠ Windows user on most setups; ask the distro directly
-- and cache in GLOBAL so subsequent reloads skip the spawn.
local WSL_USER_KEY = "launch_wsl_user"
local function wsl_user()
	local cached = wezterm.GLOBAL[WSL_USER_KEY]
	if type(cached) == "string" and cached ~= "" then return cached end
	-- Read [user] default= from /etc/wsl.conf; fall back to the UID 1000 account.
	-- (`wsl.exe -u root -- whoami` would always answer "root", which is wrong here.)
	local probe = "u=$(awk -F= '/^\\[user\\]/{s=1} s&&/^default=/{print $2; exit}' /etc/wsl.conf 2>/dev/null); "
		.. '[ -z "$u" ] && u=$(getent passwd 1000 | cut -d: -f1); '
		.. '[ -z "$u" ] && u=$(ls /home/ | head -1); printf %s "$u"'
	local ok, stdout = wezterm.run_child_process({ "wsl.exe", "-u", "root", "--", "sh", "-c", probe })
	local v = (ok and type(stdout) == "string") and stdout:gsub("%s+", "") or ""
	if v == "" then v = os.getenv("USERNAME") or "root" end
	wezterm.GLOBAL[WSL_USER_KEY] = v
	return v
end

return {
	apply_to_config = function(config)
		config.default_cwd = home

		if platform.is_win then
			local u = wsl_user()
			local wsl = { "wsl", "-u", u, "--cd", "~" }
			config.default_prog = wsl
			config.launch_menu = {
				{ label = "WSL (default; login shell)", args = wsl },
				{ label = "WSL bash", args = { "wsl", "-u", u, "--cd", "~", "bash", "-l" } },
				{ label = "WSL zsh",  args = { "wsl", "-u", u, "--cd", "~", "zsh",  "-l" } },
				{ label = "Zsh (native)",   args = { "zsh",  "-l" } },
				{ label = "Bash (native)",  args = { "bash", "-l" } },
				{ label = "PowerShell 7",   args = { "pwsh" } },
				{ label = "PowerShell 5",   args = { "powershell" } },
				{ label = "Command Prompt", args = { "cmd.exe" } },
				{ label = "admin powershell", args = { "powershell", "-command", "Start-Process powershell -Verb RunAs" } },
			}
		elseif platform.is_mac then
			config.default_prog = { "zsh", "-l" }
			config.launch_menu = {
				{ label = "Zsh (default; login)", args = { "zsh",  "-l" } },
				{ label = "Bash (login)",         args = { "bash", "-l" } },
			}
		elseif platform.is_linux then
			config.default_prog = { "bash", "-l" }
			config.launch_menu = {
				{ label = "Bash (default; login)", args = { "bash", "-l" } },
				{ label = "Zsh (login)",           args = { "zsh",  "-l" } },
			}
		end
	end,
}