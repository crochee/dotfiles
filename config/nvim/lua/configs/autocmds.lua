local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- === native LSP (nvim 0.12) ==============================================
-- 服务器配置在 rtp 根 `lsp/<name>.lua`；这里统一 enable。
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
		map("n", "<space>gtd", vim.lsp.buf.type_definition, "goto type definition")
		map("n", "<leader>gs", vim.lsp.buf.signature_help, "signature help")
		map("n", "<leader>go", vim.diagnostic.open_float, "open diagnostic float")
		-- vim.diagnostic.goto_prev/goto_next 已废弃（0.13 移除）→ jump({count})；
		-- 旧 goto_* 默认跳转后弹 float，用 on_jump 保留该行为
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

-- === 通用行为 =============================================================

-- 文件被外部修改后重新加载
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	command = "checktime",
})

-- yank 高亮
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- 打开 buffer 时回到上次退出位置
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})

-- 一些临时窗口用 <q> 关闭
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

-- 窗口尺寸变化时重新平分
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- 文本类文件 wrap + spell
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.spell = true
	end,
})

-- *.part 当作 html
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.part" },
	command = "set filetype=html",
})

-- 新行不自动注释
vim.api.nvim_create_autocmd("BufEnter", {
	group = augroup("no_auto_comment"),
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- 保存时自动创建缺失的父目录
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
