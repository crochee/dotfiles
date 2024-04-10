local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({
  "FocusGained",
  "TermClose",
  "TermLeave",
}, {
  group = augroup("checktime"),
  command = "checktime",
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  command = "silent! lua vim.highlight.on_yank()",
  group = augroup("highlight_yank"),
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd(
  "BufReadPost",
  {
    pattern = "*",
    command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]],
    group = augroup("last_loc")
  }
)

-- close some filetypes with <q>
vim.api.nvim_create_autocmd(
  "FileType", {
    group = augroup("close_with_q"),
    pattern = {
      "PlenaryTestPopup",
      "help",
      "lspinfo",
      "notify",
      "qf",
      "query",
      "spectre_panel",
      "startuptime",
      "tsplayground",
      "neotest-output",
      "checkhealth",
      "neotest-summary",
      "neotest-output-panel",
    },
    command = [[nnoremap <buffer><silent> q :close<CR>]]
  })

vim.api.nvim_create_autocmd(
  "FileType",
  {
    pattern = "man",
    command = [[nnoremap <buffer><silent> q :quit<CR>]]
  }
)

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd(
  "FileType",
  {
    group = augroup("wrap_spell"),
    pattern = { "gitcommit", "markdown" },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  })

-- auto set tab, width, etc...
vim.api.nvim_create_autocmd(
  "FileType",
  {
    pattern = { "ruby", "javascript", "html", "css", "xml", "lua" },
    command = [[set tabstop=2 shiftwidth=2 softtabstop=2 expandtab ai]]
  }
)

--set indent for jsx tsx
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = { 'javascriptreact', 'typescriptreact' },
    callback = function(opt)
      vim.bo[opt.buf].indentexpr = 'nvim_treesitter#indent()'
    end,
  })

vim.api.nvim_create_autocmd(
  { "BufRead", "BufNewFile" },
  {
    pattern = { "*.part" },
    command = [[set filetype=html]]
  }
)

-- don't auto comment new line
vim.api.nvim_create_autocmd(
  "BufEnter",
  {
    command = [[set formatoptions-=cro]]
  }
)

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd(
  { "BufWritePre" },
  {
    group = augroup("auto_create_dir"),
    callback = function(event)
      if event.match:match("^%w%w+://") then
        return
      end
      local file = vim.loop.fs_realpath(event.match) or event.match
      vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
  })

if vim.fn.has("wsl") == 1 then
  -- Set clipboard to use win32yank 设置剪贴板为win32yank,WSL与Windows同步剪贴板
  -- 下载win32yank.exe,参考http://github.com/equalsraf/win32yank/releases 将执行文件放置于/usr/local/bin/目录下
  vim.cmd [[
  let g:clipboard = {
    \   'name': 'win32yank-wsl',
    \   'copy': {
    \      '+': 'win32yank.exe -i --crlf',
    \      '*': 'win32yank.exe -i --crlf',
    \    },
    \   'paste': {
    \      '+': 'win32yank.exe -o --lf',
    \      '*': 'win32yank.exe -o --lf',
    \   },
    \   'cache_enabled': 0,
    \ }
   ]]
else
  vim.cmd [[
  let g:clipboard = {
    \   'name': 'xclip',
    \   'copy': {
    \      '+': 'xclip -selection clipboard -i',
    \      '*': 'xclip -selection clipboard -i',
    \    },
    \   'paste': {
    \      '+': 'xclip -selection clipboard -o',
    \      '*': 'xclip -selection clipboard -o',
    \   },
    \   'cache_enabled': 0,
    \ }
  ]]
end
