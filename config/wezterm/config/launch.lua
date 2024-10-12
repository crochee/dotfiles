local wezterm = require("wezterm")

local platform = require("utils.platform")()

local options = {
	default_prog = {},
	launch_menu = {},
}

if platform.is_win then
	if wezterm.target_triple == "x86_64-pc-windows-msvc" then
		options.default_prog = { "wsl", "-u", "crochee", "--cd", "~" }
	else
		options.default_prog = { "pwsh" }
	end
	options.launch_menu = {
		{ label = "admin powershell", args = { "powershell", "-command", "Start-Process powershell -Verb RunAs" } },
	}
elseif platform.is_mac or platform.is_linux then
	options.default_prog = { "bash", "-l" }
	options.launch_menu = {
		{ label = "Bash", args = { "bash", "-l" } },
	}
end

return options
