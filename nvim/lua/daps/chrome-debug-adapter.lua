local status, dap = pcall(require, "dap")
if not status then
  vim.notify("not found dap")
  return
end

local ok, mason_registry = pcall(require, "mason-registry")
if not ok then
  vim.notify("not found mason-registry")
  return
end

local chrome_debug_adapter = mason_registry.get_package("chrome-debug-adapter")
local extension_path = chrome_debug_adapter:get_install_path() .. "/out/src/chromeDebug.js"

dap.adapters.chrome = {
  type = "executable",
  command = "node",
  args = { extension_path }
}

dap.configurations.javascriptreact = { -- change this to javascript if needed
  {
    type = "chrome",
    request = "attach",
    program = "${file}",
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = "inspector",
    port = 9222,
    webRoot = "${workspaceFolder}"
  }
}

dap.configurations.typescriptreact = { -- change to typescript if needed
  {
    type = "chrome",
    request = "attach",
    program = "${file}",
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = "inspector",
    port = 9222,
    webRoot = "${workspaceFolder}"
  }
}
