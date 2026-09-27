-- project.nvim + 其自带 telescope 扩展（社区集成，替代手写的 :Projects 命令）。
--   <leader>fp  在项目根下 find_files
--   <leader>fP  切换最近项目（telescope projects 扩展，带预览）
return {
	"ahmedkhalf/project.nvim",
	lazy = false,
	priority = 1100,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("project_nvim").setup({
			patterns = require("configs.root_markers"),
			manual_mode = false,
			scope_chdir = "tab",
			silent_chdir = true,
		})
		require("telescope").load_extension("projects")

		-- 项目根下 find_files；无项目时退回 cwd
		vim.keymap.set("n", "<leader>fp", function()
			local ok, project = pcall(require, "project_nvim.project")
			local root = ok and project.get_project_root() or nil
			if type(root) == "table" then
				root = root[1]
			end
			require("telescope.builtin").find_files({
				prompt_title = "Project files",
				cwd = root or vim.fn.getcwd(),
			})
		end, { desc = "Project files (cwd = project root)" })

		-- 社区扩展：最近项目列表 + 预览，选中即 chdir
		vim.keymap.set(
			"n",
			"<leader>fP",
			"<cmd>Telescope projects<cr>",
			{ desc = "Switch project (telescope projects)" }
		)
	end,
}
