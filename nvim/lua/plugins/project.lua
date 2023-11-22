local M = {
  'ahmedkhalf/project.nvim',
  event = "VeryLazy",
}

function M.config()
  require("project_nvim").setup {
    -- All the patterns used to detect root dir, when **"pattern"** is in
    -- detection_methods
    patterns = { ".git", "Makefile", "package.json" },

    -- Table of lsp clients to ignore by name
    -- eg: { "efm", ... }
  }
end

return M
