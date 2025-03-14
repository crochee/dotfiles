local parse_curl_args = function(opts, code_opts)
	local user_content = {}
	local Config = require("avante.config")
	if Config.behaviour.support_paste_from_clipboard and code_opts.image_paths and #code_opts.image_paths > 0 then
		local Clipboard = require("avante.clipboard")
		for _, image_path in ipairs(code_opts.image_paths) do
			table.insert(user_content, {
				type = "image_url",
				image_url = {
					url = "data:image/png;base64," .. Clipboard.get_base64_content(image_path),
				},
			})
		end
	end
	vim.iter(code_opts.messages):each(function(prompt)
		table.insert(user_content, { type = "text", text = prompt.content })
	end)
	local messages = {
		{ role = "system", content = code_opts.system_prompt },
		{ role = "user", content = user_content },
	}
	if not opts.disable_tools and opts.tool_histories then
		for _, tool_history in ipairs(code_opts.tool_histories) do
			table.insert(messages, {
				role = "assistant",
				tool_calls = {
					{
						id = tool_history.tool_use.id,
						type = "function",
						["function"] = {
							name = tool_history.tool_use.name,
							arguments = tool_history.tool_use.input_json,
						},
					},
				},
			})
			local result_content = tool_history.tool_result.content or ""
			table.insert(messages, {
				role = "tool",
				tool_call_id = tool_history.tool_result.tool_use_id,
				content = tool_history.tool_result.is_error and "Error: " .. result_content or result_content,
			})
		end
	end
	return {
		url = opts.endpoint,
		timeout = opts.timeout,
		insecure = false,
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. os.getenv(opts.api_key_name),
		},
		body = {
			model = opts.model,
			max_tokens = opts.max_tokens,
			temperature = 0.3,
			top_p = 1.0,
			stream = true,
			messages = messages,
		},
	}
end

local parse_response = function(ctx, ex, event_state, data, opts)
	require("avante.providers.openai").parse_response(ctx, ex, event_state, data, opts)
end

return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
	opts = {
		provider = "kimi",
		vendors = {
			kimi = {
				endpoint = "https://api.moonshot.cn/v1/chat/completions",
				model = "moonshot-v1-32k", -- "moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"
				api_key_name = "LLM_KEY",
				parse_curl_args = parse_curl_args,
				parse_response = parse_response,
				is_disable_stream = function()
					return false
				end,
				max_tokens = 4096,
				timeout = 30000,
				-- important to set this to true if you are using a local server
				disable_tools = false,
			},
		},
		file_selector = {
			provider = "telescope",
		},
	},
	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	build = "make",
	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
