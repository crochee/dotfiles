local dap = require('dap')
--codelldb地址https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb
-- https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vadimcn/vsextensions/vscode-lldb/1.9.2/vspackage
local extension_path = vim.env.HOME .. '/.vscode/extensions/vadimcn.vscode-lldb-1.9.2/'
local codelldb_path = extension_path .. 'adapter/codelldb'
local liblldb_path = extension_path .. 'lldb/lib/liblldb'
local this_os = vim.loop.os_uname().sysname;
local package_path = '' -- set your windows path
-- The path in windows is different
if this_os:find "Windows" then
  codelldb_path = package_path .. "adapter\\codelldb.exe"
  liblldb_path = package_path .. "lldb\\bin\\liblldb.dll"
else
  -- The liblldb extension is .so for linux and .dylib for macOS
  liblldb_path = liblldb_path .. (this_os == "Linux" and ".so" or ".dylib")
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
    stopOnEntry = false,
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
local executableArgs = {}
dap.configurations.rust = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      local input = vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      executableArgs = {}
      for word in string.gmatch(input, '%S+') do
        table.insert(executableArgs, word)
      end
      if #executableArgs > 1 then
        table.insert(executableArgs, "--exact")
        table.insert(executableArgs, "--nocapture")
      end
      local path = executableArgs[1]
      table.remove(executableArgs, 1)
      return path
    end,
    args = executableArgs or {}, -- 参考vscode 的debug设置
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    sourceLanguages = {
      "rust"
    },
    runInTerminal = false,
  },
}
