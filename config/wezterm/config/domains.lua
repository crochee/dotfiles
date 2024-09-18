local wezterm = require("wezterm")
local ssh_domains = wezterm.default_ssh_domains()
for _, dom in ipairs(ssh_domains) do
	dom.assume_shell = "bash"
end

return {
	-- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
	ssh_domains = ssh_domains,

	-- -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
	-- unix_domains = {},
	--
	-- -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
	-- wsl_domains = {},
}
