# nvim (0.12+, lazy.nvim)

Plugin specs in `lua/plugins/*.lua`. Loading is `defaults.lazy = true` with explicit `keys` / `event` / `cmd` / `ft` triggers; `<leader>fg/ff/fp/...` etc. are surfaced to wezterm via `lua/configs/wezterm-osc.lua` (OSC 1337 → `NVIM_KEYS`), so terminal-side key forwarding picks the right consumer.

Hand-rolled (not duplicated by any community plugin):
- `lua/configs/wezterm-osc.lua` — OSC publisher (see wezterm `bindings.lua` `dispatch()`).
- `lua/configs/{autocmds,keymaps,options,lazynvim,root_markers}.lua` — base layer.
- `ftplugin/go.lua` — `iferr` CLI thin wrapper (no maintained plugin).
- `lua/plugins/toggleterm.lua` — `<leader>tg/tF/lt/gl` (lazygit float, git log -L, send-to-term). Functional surface is too small to pull in vim-fugitive / lazygit.nvim.
- `lua/plugins/conform.lua` — `DiffFormat` (format only git-diff lines; no community equivalent).
- `lua/plugins/perf.lua` — `:Profile start|stop|status` wrapper around `stevearc/profile.nvim` (plugin ships no command).

Keymap authority is `docs/KEYMAP.md`.