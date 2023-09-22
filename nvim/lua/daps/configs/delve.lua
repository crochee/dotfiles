local status, dapGo = pcall(require, "dap-go")
if not status then
  vim.notify("not found nvim-dap-go")
  return
end
dapGo.setup()
