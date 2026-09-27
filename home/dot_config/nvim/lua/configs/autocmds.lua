local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- === native LSP (nvim 0.12) ==============================================
-- Per-server configs in `lua/lsp/<name>.lua`; nvim 0.12 needs `vim.lsp.config(name, t)`
-- BEFORE `vim.lsp.enable(name)` (enable alone only registers startup signals, so per-server
-- customizations — yamlls k8s schema, gopls staticcheck, eslint vue/svelte/astro,
-- lua_ls runtime — would silently drop).
local SERVERS = {
	"bashls",
	"clangd",
	"cssls",
	"eslint",
	"gopls",
	"html",
	"jdtls",
	"jsonls",
	"kotlin_language_server",
	"lua_ls",
	"pyright",
	"taplo",
	"ts_ls",
	"vimls",
	"yamlls",
}
for _, name in ipairs(SERVERS) do
	local ok, cfg = pcall(require, "lsp." .. name)
	if ok then
		vim.lsp.config(name, cfg)
	else
		-- 配置缺失时不静默——直接报, 避免再次陷入 "写了不生效" 的坑
		vim.notify("lsp config missing: " .. name .. " (" .. tostring(cfg) .. ")", vim.log.levels.WARN)
	end
end
vim.lsp.enable(SERVERS)

-- LspAttach：buffer 局部键位（替代旧 opts.on_attach）。
-- nvim 0.12 内置默认键位（grn/grr/gri/gra/gO/K/Ctrl-S）自动生效。
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end
		local buf = ev.buf

		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = "LSP: " .. desc, silent = true })
		end

		map("n", "<leader>rn", vim.lsp.buf.rename, "rename")
		map("n", "<leader>ca", vim.lsp.buf.code_action, "code action")
		map("n", "<leader>gd", vim.lsp.buf.definition, "goto definition")
		map("n", "<leader>gh", vim.lsp.buf.hover, "hover")
		map("n", "<leader>gD", vim.lsp.buf.declaration, "goto declaration")
		map("n", "<leader>gi", vim.lsp.buf.implementation, "goto implementation")
		map("n", "<leader>gr", vim.lsp.buf.references, "references")
		map("n", "<leader>gtd", vim.lsp.buf.type_definition, "goto type definition")
		map("n", "<leader>gs", vim.lsp.buf.signature_help, "signature help")
		map("n", "<leader>go", vim.diagnostic.open_float, "open diagnostic float")
		-- diagnostic.jump({count, on_jump}) replaces goto_prev/goto_next (0.13); on_jump preserves the float.
		local function diagnostic_jump(count)

			return function()
				vim.diagnostic.jump({
					count = count,
					on_jump = function(_, bufnr)
						vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
					end,
				})
			end
		end
		map("n", "<leader>gp", diagnostic_jump(-1), "prev diagnostic")
		map("n", "<leader>gn", diagnostic_jump(1), "next diagnostic")
	map("n", "<leader>gq", vim.diagnostic.setloclist, "diagnostics to loclist")
end,
})

-- === general =============================================================

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	command = "checktime",
})

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})

-- 临时窗口用 <q> 关闭 (pattern 列表: help / qf / neotest / etc.).
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"PlenaryTestPopup",
		"help",
		"lspinfo",
		"qf",
		"query",
		"checkhealth",
		"neotest-output",
		"neotest-summary",
		"neotest-output-panel",
		"man",
	},
	callback = function(ev)
		vim.keymap.set("n", "q", vim.cmd.close, { buffer = ev.buf, silent = true })
	end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.spell = true
	end,
})

-- *.part 当作 html (augroup 让 :source $MYVIMRC 重 source 不累积副本).
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = augroup("part_filetype"),
	pattern = { "*.part" },
	command = "set filetype=html",
})

vim.api.nvim_create_autocmd("BufEnter", {
	group = augroup("no_auto_comment"),
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})
