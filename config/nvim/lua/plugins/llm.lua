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

			-- [[ kimi ]]
			url = "https://api.moonshot.cn/v1/chat/completions",
			model = "moonshot-v1-32k", -- "moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"
			api_type = "openai",

			max_history = 15,
			temperature = 0.3,
			top_p = 0.7,
			app_handler = {
				TestCode = {
					handler = tools.side_by_side_handler,
					prompt = [[ Write some test cases for the following code, only return the test cases.
            Give the code content directly, do not use code blocks or other tags to wrap it. ]],
					opts = {
						right = {
							title = " Test Cases ",
						},
					},
				},
				OptimCompare = {
					handler = tools.action_handler,
				},
				Translate = {
					handler = tools.qa_handler,
					opts = {
						component_width = "60%",
						component_height = "50%",
						query = {
							title = " 󰊿 Trans ",
							hl = { link = "Define" },
						},
						input_box_opts = {
							size = "15%",
							win_options = {
								winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
							},
						},
						preview_box_opts = {
							size = "85%",
							win_options = {
								winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
							},
						},
					},
				},
				WordTranslate = {
					handler = tools.flexi_handler,
					prompt = "Translate the following text to Chinese, please only return the translation",
					opts = {
						exit_on_move = true,
						enter_flexible_window = false,
					},
				},
				CodeExplain = {
					handler = tools.flexi_handler,
					prompt = "Explain the following code, please only return the explanation, and answer in Chinese",
					opts = {
						enter_flexible_window = true,
					},
				},
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
