local M = {
  'ahmedkhalf/project.nvim',
  event = "VeryLazy",
}

function M.config()
  local status, project = pcall(require, "project_nvim")
  if not status then
    vim.notify("没有找到 project_nvim")
    return
  end
  project.setup {
    -- All the patterns used to detect root dir, when **"pattern"** is in
    -- detection_methods
    patterns = { ".git", "Makefile", "package.json" },

    -- Table of lsp clients to ignore by name
    -- eg: { "efm", ... }
  }
  require("telescope").load_extension("projects")
end

return M
