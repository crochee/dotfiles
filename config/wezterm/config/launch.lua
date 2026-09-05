local wezterm = require("wezterm")

local platform = require("utils.platform")()

local options = {
	default_prog = {},
	launch_menu = {},
}

if platform.is_win then
	-- Windows：default 走 WSL，**显式追加 fish**（不依赖 wsl 内的 $SHELL）
	-- wsl.exe 把 args 直接转发到 wsl 内的 init 进程；末尾加 "fish" 让 wsl 启动 fish
	-- 即便 wsl 内 chsh 失败/未切，这层也强制进 fish
	if wezterm.target_triple == "x86_64-pc-windows-msvc" then
		options.default_prog = { "wsl", "-u", "crochee", "--cd", "~", "fish", "-l" }
	else
		-- ARM Windows：无 WSL 主流路径，fallback pwsh
		options.default_prog = { "pwsh" }
	end
	options.launch_menu = {
		{ label = "WSL fish (default)", args = { "wsl", "-u", "crochee", "--cd", "~", "fish", "-l" } },
		{ label = "WSL zsh", args = { "wsl", "-u", "crochee", "--cd", "~", "zsh", "-l" } },
		{ label = "WSL bash", args = { "wsl", "-u", "crochee", "--cd", "~", "bash", "-l" } },
		{ label = "WSL (login shell)", args = { "wsl", "-u", "crochee", "--cd", "~" } },
		{ label = "Fish (native)", args = { "fish", "-l" } },
		{ label = "Zsh (native)", args = { "zsh", "-l" } },
		{ label = "Bash (native)", args = { "bash", "-l" } },
		{ label = "PowerShell 7", args = { "pwsh" } },
		{ label = "PowerShell 5", args = { "powershell" } },
		{ label = "Command Prompt", args = { "cmd.exe" } },
		{ label = "admin powershell", args = { "powershell", "-command", "Start-Process powershell -Verb RunAs" } },
	}
elseif platform.is_mac then
	-- macOS：fish（默认）+ zsh（备选）
	options.default_prog = { "fish", "-l" }
	options.launch_menu = {
		{ label = "Fish (default)", args = { "fish" } },
		{ label = "Fish login", args = { "fish", "-l" } },
		{ label = "Zsh (login)", args = { "zsh", "-l" } },
	}
elseif platform.is_linux then
	-- Linux：fish（默认）+ bash（备选）
	options.default_prog = { "fish", "-l" }
	options.launch_menu = {
		{ label = "Fish (default)", args = { "fish" } },
		{ label = "Fish login", args = { "fish", "-l" } },
		{ label = "Bash (login)", args = { "bash", "-l" } },
	}
end

return options
