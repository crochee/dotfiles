return {
	apply_to_config = function(config)
		config.automatically_reload_config = true
		config.exit_behavior = "CloseOnCleanExit"
		config.exit_behavior_messaging = "Verbose"
		config.status_update_interval = 1000

		-- Strip wrapping brackets/parens/braces from URLs so links open cleanly.
		config.hyperlink_rules = {
			{ regex = "\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b", format = "$0" },
			{ regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],            format = "mailto:$0" },
			{ regex = [[\bfile://\S*\b]],                       format = "$0" },
			{ regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]], format = "$0" },
			{ regex = "\\((\\w+://\\S+)\\)", format = "$1", highlight = 1 },
			{ regex = "\\[(\\w+://\\S+)\\]", format = "$1", highlight = 1 },
			{ regex = "\\{(\\w+://\\S+)\\}", format = "$1", highlight = 1 },
			{ regex = "<(\\w+://\\S+)>",    format = "$1", highlight = 1 },
		}
	end,
}