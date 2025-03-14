return {
	"Kurama622/llm.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
	cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
	config = function()
		local tools = require("llm.common.tools")
		require("llm").setup({
			prompt = "You are a helpful chinese assistant.",

			prefix = {
				user = { text = "😃 ", hl = "Title" },
				assistant = { text = "⚡ ", hl = "Added" },
			},
			keys = {
				["Session:Toggle"] = { mode = "n", key = "<leader>all" },
				["Session:Close"] = { mode = "n", key = { "<esc>", "Q" } },
			},
			-- [[ kimi ]]
			url = "https://api.moonshot.cn/v1/chat/completions",
			model = "moonshot-v1-32k", -- "moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"
			api_type = "openai",

			max_history = 15,
			temperature = 0.3,
			top_p = 0.7,
			app_handler = {
				CommitMsg = {
					handler = tools.flexi_handler,
					prompt = function()
						return string.format(
							[[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:
1. Start with an action verb (e.g., feat, fix, refactor, chore, etc.), followed by a colon.
2. Briefly mention the file or module name that was changed.
3. Describe the specific changes made.
4. must match ^(feat|fix|docs|style|refactor|perf|test|chore|revert|build|ci)(\(.+\))?:\s.{1,125}

Examples:
- feat: update common/util.py, added test cases for util.py
- fix: resolve bug in user/auth.py related to login validation
- refactor: optimize database queries in models/query.py

Based on this format, generate appropriate commit messages. Respond with message only. DO NOT format the message in Markdown code blocks, DO NOT use backticks:

```diff
%s
```
]],
							vim.fn.system("git diff --no-ext-diff --staged")
						)
					end,
					opts = {
						enter_flexible_window = true,
						apply_visual_selection = false,
						win_opts = {
							relative = "editor",
							position = "50%",
						},
						accept = {
							mapping = {
								mode = "n",
								keys = "<cr>",
							},
							action = function()
								local contents = vim.api.nvim_buf_get_lines(0, 0, -1, true)
								vim.api.nvim_command(
									string.format('!git commit -m "%s"', table.concat(contents, '" -m "'))
								)
							end,
						},
					},
				},
				DocString = {
					prompt = [[ You are an AI programming assistant. You need to write a really good docstring that follows a best practice for the given language.

Your core tasks include:
- parameter and return types (if applicable).
- any errors that might be raised or returned, depending on the language.

You must:
- Place the generated docstring before the start of the code.
- Follow the format of examples carefully if the examples are provided.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.]],
					handler = tools.action_handler,
					opts = {
						only_display_diff = true,
						templates = {
							lua = [[- For the Lua language, you should use the LDoc style.
- Start all comment lines with "---".
]],
						},
					},
				},
			},
		})
	end,
}
