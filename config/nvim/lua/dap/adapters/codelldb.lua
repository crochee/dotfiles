-- codelldb 适配器（mason 安装）；供 nvim-dap 与 rustaceanvim 共用
local extension_path = vim.fn.expand("$MASON/packages/codelldb/extension")
local codelldb_path = extension_path .. "/adapter/codelldb"
local liblldb_path = ""
if vim.uv.os_uname().sysname:find("Windows") then
	liblldb_path = extension_path .. "lldb\\bin\\liblldb.dll"
elseif vim.fn.has("mac") == 1 then
	liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
else
	liblldb_path = extension_path .. "lldb/lib/liblldb.so"
end

return {
	type = "server",
	port = "${port}",
	executable = {
		command = codelldb_path,
		args = { "--liblldb", liblldb_path, "--port", "${port}" },
		detached = vim.fn.has("win32") == 0,
	},
}
