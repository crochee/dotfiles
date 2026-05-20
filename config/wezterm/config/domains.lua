local wezterm = require("wezterm")
local ssh_domains = wezterm.default_ssh_domains()

return {
	-- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
	ssh_domains = ssh_domains,

	-- -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
	-- unix_domains = {},
	--
	-- -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
	-- wsl_domains = {},
}
