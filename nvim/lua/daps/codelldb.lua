local status, dap = pcall(require, "dap")
if not status then
  vim.notify("not found dap")
  return
end
--codelldb地址https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb
-- https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vadimcn/vsextensions/vscode-lldb/1.9.2/vspackage
-- rust tools configuration for debugging support
local ok, mason_registry = pcall(require, "mason-registry")
if not ok then
  vim.notify("not found mason-registry")
end

local codelldb = mason_registry.get_package("codelldb")
local extension_path = codelldb:get_install_path() .. "/extension/"
local codelldb_path = extension_path .. "adapter/codelldb"
local liblldb_path = ""
if vim.loop.os_uname().sysname:find("Windows") then
  liblldb_path = extension_path .. "lldb\\bin\\liblldb.dll"
elseif vim.fn.has("mac") == 1 then
  liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
else
  liblldb_path = extension_path .. "lldb/lib/liblldb.so"
end
-- 参考 dap.configurations.codelldb
dap.adapters.codelldb = {
  type = 'server',
  port = '${port}',
  executable = {
    command = codelldb_path,
    args = { "--liblldb", liblldb_path, '--port', '${port}' },
    detached = vim.fn.has('win32') == 0,
  },
}

dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
  },
}

dap.configurations.c = dap.configurations.cpp

-- rust 配置函数编写
--  rust unittests
-- 正在执行任务: cargo test --package server --lib -- services::authorization::matcher::reg::tests::build --exact --nocapture
--
--    Finished test [unoptimized + debuginfo] target(s) in 0.14s
--     Running unittests src/lib.rs (target/debug/deps/server-ca0f74b0471de00d)
-- configurations
-- {"type": "lldb",
--   "request": "launch",
--   "name": "test services::authorization::matcher::reg::tests::build",
--   "program": "${workspaceFolder}/target/debug/deps/server-ca0f74b0471de00d",
--   "args": [
--     "services::authorization::matcher::reg::tests::build",
--     "--exact",
--     "--nocapture"
--   ],
--   "cwd": "${workspaceFolder}",
--   "sourceMap": {},
--   "sourceLanguages": [
--     "rust"
--   ],}

-- 执行服务debug
-- cargo build --bin server
-- configurations
-- {"type": "lldb",
--   "request": "launch",
--   "name": "run server",
--   "program": "${workspaceFolder}/target/debug/server",
--   "args": [],
--   "cwd": "${workspaceFolder}",
--   "sourceMap": {},
--   "sourceLanguages": [
--     "rust"
--   ],}
