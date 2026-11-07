# omp-workbench

A session workbench and an editor surface for [omp](https://omp.sh).

Two surfaces, both drawn by the extension itself on the terminal's alternate
screen, so the conversation on the normal screen is left untouched and the
session keeps working while a surface is open:

- **`/workbench`** — a full-screen workbench over the session list. Filter
  sessions by typing, read the transcript outline of the selected session,
  switch to another session, or delete one.
- **`/editor`** — a full-screen view with **Files**, **Git**, **Sessions**, and
  **Jobs** pages. The Files page hands the terminal to nvim with
  **nvim-tree** open at the project root, so the file tree is the real
  plugin, with its own mappings, filters, and devicons.

Shortcuts: `Alt+W` opens the workbench, `Alt+B` opens the editor surface. The
shortcut cannot switch sessions (a shortcut handler has no session action);
`/workbench` and `/editor` can.

### Workbench keys

| Key | Action |
| --- | --- |
| type | filter sessions and projects |
| `↑` / `↓` | move in the list |
| `Enter` | open a project group, or switch to a session |
| `Tab` | toggle scope: all projects / this project only |
| `Ctrl+S` | switch to the selected session |
| `Ctrl+D` | delete the selected session (asks `y` / `n` inline) |
| `Ctrl+R` | reload the list |
| `PageUp` / `PageDown` | scroll the transcript outline |
| `?` | show the key map |
| `Alt+W` / `Esc` | close the workbench |

Sessions are grouped by project. The running session's project heads the list,
marked with `●`, and starts expanded; every other project shows only its
header and session count until it is opened. Filtering flattens the groups: a
query that names a project path reveals that project's sessions, and a query
that matches a title keeps it under its project.

The delete confirmation is drawn inside the panel: a host dialog would be
hidden behind the full-screen overlay. Which project groups are open is
remembered between sessions.

### Editor keys

The surface binds `Tab` / `Shift+Tab` (next / previous page), `1`–`9` (jump
to a page), `?` (the key map) and `Esc` (close). Every page binds keys of
its own, and the key map shows the page you are on together with the
surface's own keys.

| Page | Keys |
| --- | --- |
| Files | `Enter` / `t` / `e` open the file tree in nvim (nvim-tree) · `/` quick open a file by path · `n` create a file and open it · `d` delete a file · `h` list dotfiles in the quick open · `r` check again for nvim-tree |
| Git | `↑` `↓` move · `Enter` stage the file, or unstage it · `r` reload |
| Sessions | type to filter · `↑` `↓` move · `Enter` switch to the session · `t` toggle scope · `r` reload |
| Jobs | `↑` `↓` move · `r` reload |

The quick open lists the project with `rg --files` (a bounded walk takes over
when ripgrep is missing) and filters by path substring; `Ctrl+D` deletes the
selected match. Whether the quick open lists dotfiles is remembered between
sessions.

The page asks nvim whether it can load nvim-tree before opening it, and says
so in the panel, with the install command when the plugin is missing.

Opening nvim stops the TUI, hands the terminal over, and starts the TUI
again afterwards — the surface comes back exactly where it was.

A page is built when it is first shown, so opening the surface costs the
work of the page you land on and nothing else.

### The pane model

Both surfaces follow the rules Claude Code uses for the panes its own mods
draw:

- **The alternate screen, not an overlay.** The surface takes the whole page
  and leaves the transcript on the normal screen exactly as it was, so the
  session is never blocked: it keeps working while a surface is open, and the
  header says whether it is `working` or `idle`.
- **Escape closes it**, and the composer comes straight back.
- **A surface may hand the terminal over.** Opening a file stops the TUI,
  gives the terminal to the editor, and starts the TUI again afterwards.

## State

The panel state lives in `${XDG_STATE_HOME:-~/.local/state}/omp-workbench/state.json`:
which project groups are open, and whether the quick open lists dotfiles.

## Layout

```
src/
  index.ts                extension entry: commands, shortcuts, editor pages
  ui/chrome.ts            panel frame, split geometry, ANSI-aware padding
  ui/format.ts            relative time, file size, path helpers
  sessions/source.ts      session listing (project scope and all projects)
  sessions/outline.ts     turn-structured outline of a session file
  sessions/host.ts        session capabilities + session file deletion
  workbench/workbench.ts  the full-screen session workbench
  editor/panel.ts         the full-screen editor surface
  editor/list.ts          the scrolling list the pages share
  editor/search.ts        the project file index (ripgrep, or a bounded walk)
  editor/nvim-tree.ts     asking nvim about nvim-tree, and opening it
  editor/launch.ts        handing the terminal to nvim or $EDITOR
  editor/git.ts           git state: branch, working tree, commits
  editor/registry.ts      registry other plugins use to add pages
  editor/tabs/            files, git, sessions, jobs pages
  editor/filter.ts        type-to-filter for the pages
  editor/tab.ts           the page contract (keys, rendering, input)
```

Every page describes its keys in one place (`keys()`); the key bar and the
key map are both built from that table, so they cannot drift apart.

## Install

The plugin lives in omp's native user-extension directory:

```
~/.omp/agent/extensions/omp-workbench/
```

`~/.omp/agent/extensions` is auto-discovered by omp, so the directory is all
it takes — no configuration, no symlink. `omp plugin link
~/.omp/agent/extensions/omp-workbench` also works.

## Pages from other plugins

Any extension can contribute a page:

```ts
globalThis.ompWorkbench?.registerTab({
  id: "my-plugin:db",
  label: "Database",
  create: context => ({
    id: "my-plugin:db",
    label: "Database",
    render: (width, height) => [`${context.host.ctx.cwd} (${width}x${height})`],
    handleInput: data => data === "r",
  }),
});
```

`context` carries the session host (`ctx`, optional `switchSession` and
`dropSession`), the live theme, the TUI, an `exec` runner, the session state
(`working` / `idle`), and `refresh`, `notify`, and `close` helpers.

A page may also implement `keys()` (the key bar and the key map), `activate()`
(reload the page's data when it becomes visible), and `capturesKeys()` (true
while the page owns the keyboard, such as a text prompt).

## Typecheck

The plugin imports omp's own packages, which are not published to npm:

```sh
bun add -d typescript @types/node
bunx tsc -p tsconfig.json
```

`tsconfig.json` maps `@oh-my-pi/pi-tui` and `@oh-my-pi/pi-coding-agent` to the
copies omp installs under `~/.local/share/omp/plugins/node_modules` (four
levels up from this directory).
