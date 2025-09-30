return {
  "LunarVim/bigfile.nvim",
  event = "BufReadPre",
  -- Disables LSP/treesitter, etc for files above 5000 lines (even if they have really long lines)
  opts = {
    filesize = 10,
    pattern = function(bufnr, filesize_mib)
      if filesize_mib >= 10 then
        return true
      end
      -- you can't use `nvim_buf_line_count` because this runs on BufReadPre
      local file_contents = vim.fn.readfile(vim.api.nvim_buf_get_name(bufnr))
      local file_length = #file_contents
      if file_length > 20000 then
        return true
      end

      return false
    end,
  },
}
