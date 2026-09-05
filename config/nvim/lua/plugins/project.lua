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
			-- detection patterns; project.nvim finds project root by these
			patterns = { ".git", "pom.xml", "*.csproj", "Makefile", "Cargo.toml", "go.mod", "package.json", "pyproject.toml" },
			-- 自动 chdir 到项目根（manual_mode=false 即默认行为）
			manual_mode = false,
			-- 目录切换作用域：tab（原 terminal_scope 意图）
			scope_chdir = "tab",
			silent_chdir = true,
		})

		-- helper: get the active project root directory (or nil if none)
		local function project_root()
			local ok, project = pcall(require, "project_nvim.project")
			if not ok then
				return nil
			end
			local root = project.get_project_root()
			return type(root) == "table" and root[1] or root
		end

		-- Telescope: project files picker (cwd = project root)
		vim.keymap.set("n", "<leader>fp", function()
			local cwd = project_root() or vim.fn.getcwd()
			require("telescope.builtin").find_files({
				prompt_title = "Project files",
				cwd = cwd,
			})
		end, { desc = "Project files (cwd = project root)" })

		-- Telescope: switch project picker (cwd = project root of current buf, lists files inside)
		vim.keymap.set("n", "<leader>fP", function()
			local cwd = project_root() or vim.fn.getcwd()
			require("telescope.builtin").find_files({
				prompt_title = "Projects",
				cwd = cwd,
			})
		end, { desc = "Pick project files (from root)" })

		-- list recent projects and jump to one
		vim.api.nvim_create_user_command("Projects", function()
			local recent = require("project_nvim").get_recent_projects()
			if vim.tbl_isempty(recent) then
				vim.notify("no recent projects", vim.log.levels.INFO)
				return
			end
			vim.ui.select(recent, { prompt = "Switch project" }, function(choice)
				if not choice then
					return
				end
				local ok_p, project = pcall(require, "project_nvim.project")
				if ok_p then
					project.set_pwd(choice, "manual")
				end
			end)
		end, { desc = "Switch to a recent project" })
	end,
}