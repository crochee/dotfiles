local M = {
  "lukas-reineke/indent-blankline.nvim",
  event = "VeryLazy"
}

--编辑块的竖线提示

function M.config()
  require("indent_blankline").setup {
    -- empty line placeholder
    space_char_blankline = " ",
    -- Judging context with treesitter
    show_current_context = true,
    show_current_context_start = true,
    context_patterns = {
      "class",
      "function",
      "method",
      "element",
      "^if",
      "^while",
      "^for",
      "^object",
      "^table",
      "block",
      "arguments",
      "if_statement",
      "else_clause",
      "jsx_element",
      "jsx_self_closing_element",
      "try_statement",
      "catch_clause",
      "import_statement",
      "operation_type",
    },
    -- :echo &filetype
    filetype_exclude = {
      "alpha",
      "terminal",
      "help",
      "log",
      "markdown",
      "TelescopePrompt",
      "lsp-installer",
      "lspinfo",
      "toggleterm",
      "startify",
      "dashboard",
      "lazy",
      "NvimTree",
      "Trouble",
    },
    -- vertical bar style
    -- char = '¦'
    -- char = '┆'
    -- char = '│'
    -- char = "⎸",
    -- char = "▏",
  }
end

return M
