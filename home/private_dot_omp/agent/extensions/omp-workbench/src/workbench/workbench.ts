/**
 * Full-screen session workbench.
 *
 * Left column: every session of the current project (or of every project),
 * filterable by typing and grouped by project in the wide scope. Right
 * column: what the selected session is — its metadata and a turn-structured
 * outline of its transcript. Actions: switch to a session, delete one,
 * refresh the list, read the key map.
 */
import {
	type Component,
	Key,
	type SelectItem,
	type SelectListRenderItemContext,
	SelectList,
	type TUI,
	getSelectListTheme,
	matchesKey,
} from "@oh-my-pi/pi-tui";
import type { Theme } from "@oh-my-pi/pi-tui/theme";
import {
	badge,
	bottomBorder,
	dividerSplit,
	fit,
	fullRow,
	keyValueRows,
	metaHeader,
	rightAligned,
	sectionHeader,
	splitBodyWidth,
	splitRow,
	topBorder,
	topBorderSplit,
	wrapIndented,
} from "../ui/chrome";
import { statusColor, timeAgo, timestamp, fileSize } from "../ui/format";
import type { SessionHost } from "../sessions/host";
import { loadSessions, type SessionRow, type SessionScope } from "../sessions/source";
import { readSessionOutline, type SessionOutline } from "../sessions/outline";
import { loadState, saveState } from "../state";

export interface WorkbenchOptions {
	host: SessionHost;
	tui: TUI;
	theme: Theme;
	done: (result: undefined) => void;
}

const OUTLINE_LABEL = {
	user: "you",
	assistant: "ai",
	tool: "tool",
	note: "note",
} as const;

const HELP_LINES: readonly (readonly [string, string])[] = [
	["↑ ↓", "move in the session list"],
	["type", "filter the list"],
	["tab", "toggle scope: all projects / this project only"],
	["enter", "open a project group, or switch to a session"],
	["ctrl+s", "switch to the selected session"],
	["ctrl+d", "delete the selected session (y / n)"],
	["ctrl+r", "reload the list"],
	["pgup / pgdn", "scroll the transcript outline"],
	["?", "toggle this help"],
	["esc", "close the workbench"],
];

export class WorkbenchPanel implements Component {
	readonly #host: SessionHost;
	readonly #tui: TUI;
	readonly #theme: Theme;
	readonly #done: (result: undefined) => void;
	readonly #list: SelectList;
	#scope: SessionScope = "all";
	#rows: SessionRow[] = [];
	#rowByPath = new Map<string, SessionRow>();
	/** Every row with its groups expanded; the filter works on this list. */
	#flatItems: SelectItem[] = [];
	/** Project path of the running session; it heads the list and starts expanded. */
	#currentProject = "";
	/** Explicit open/closed state per project; unset projects follow the default. */
	#groupState = new Map<string, "open" | "closed">();
	#selected: SessionRow | undefined;
	/** Project whose header is selected; the detail pane summarizes it. */
	#selectedProject: string | undefined;
	#outline: SessionOutline = { items: [], truncated: false };
	#outlineFor: string | undefined;
	#loading = false;
	#notice: string | undefined;
	#detailScroll = 0;
	#generation = 0;
	#closed = false;
	/** Pending inline delete confirmation; the panel owns it so no dialog can hide behind the overlay. */
	#confirming: { path: string; title: string } | undefined;
	#help = false;

	constructor(options: WorkbenchOptions) {
		this.#host = options.host;
		this.#tui = options.tui;
		this.#theme = options.theme;
		this.#done = options.done;
		this.#currentProject = options.host.ctx.cwd;
		this.#list = new SelectList([], 10, getSelectListTheme(), {
			emptyText: "No sessions",
			noMatchText: "No matching sessions",
			renderItem: context => this.#renderItem(context),
			measureItem: context => this.#renderItem(context).length,
			filterItems: (items, query) => this.#filterItems(items, query),
		});
		this.#list.onSelectionChange = item => this.#onSelection(item);
		this.#list.onSelect = item => {
			if (item.value.startsWith("group:")) {
				this.#toggleGroup(item.value.slice("group:".length));
				return;
			}
			void this.#switchTo(item.value);
		};
		this.#list.onCancel = () => this.#close();
		this.#list.setMaxVisible(Math.max(5, this.#tui.terminal.rows - 7));
		void this.#reload();
	}

	render(width: number): readonly string[] {
		const theme = this.#theme;
		const total = Math.max(40, width);
		const height = Math.max(10, this.#tui.terminal.rows);
		const contentRows = Math.max(1, height - 4);
		// The list keeps its own scroll budget; a resized terminal changes it.
		this.#list.setMaxVisible(Math.max(5, height - 7));

		if (this.#help) {
			const lines: string[] = [topBorder(theme, total, "Session Workbench · keys")];
			const body = this.#helpRows(total - 4);
			for (let index = 0; index < contentRows; index++) {
				lines.push(fullRow(theme, body[index] ?? "", total));
			}
			lines.push(fullRow(theme, this.#keybar(), total));
			lines.push(bottomBorder(theme, total));
			return lines;
		}

		const leftWidth = Math.min(Math.max(28, Math.floor(total * 0.38)), Math.max(12, total - 46));
		const bodyWidth = splitBodyWidth(total, leftWidth);
		const listRows = this.#list.render(leftWidth);
		const detailRows = this.#detailRows(bodyWidth, contentRows - 1);
		const lines: string[] = [topBorderSplit(theme, total, "Session Workbench", leftWidth)];
		lines.push(
			splitRow(theme, this.#listHeader(leftWidth), this.#detailHeader(bodyWidth), total, leftWidth),
		);
		for (let index = 0; index < contentRows - 1; index++) {
			lines.push(splitRow(theme, listRows[index] ?? "", detailRows[index] ?? "", total, leftWidth));
		}
		lines.push(dividerSplit(theme, total, leftWidth));
		lines.push(fullRow(theme, this.#keybar(), total));
		lines.push(bottomBorder(theme, total));
		return lines;
	}

	handleInput(data: string): void {
		if (this.#closed) return;
		if (this.#help) {
			this.#help = false;
			this.#tui.requestRender();
			return;
		}
		if (this.#confirming) {
			this.#handleConfirmInput(data);
			return;
		}
		if (
			matchesKey(data, Key.escape) ||
			matchesKey(data, Key.ctrl("c")) ||
			matchesKey(data, Key.alt("w"))
		) {
			this.#close();
			return;
		}
		if (data === "?") {
			this.#help = true;
			this.#tui.requestRender();
			return;
		}
		if (matchesKey(data, Key.ctrl("r"))) {
			void this.#reload();
			return;
		}
		if (matchesKey(data, Key.ctrl("s"))) {
			void this.#switchTo(this.#list.getSelectedItem()?.value);
			return;
		}
		if (matchesKey(data, Key.ctrl("d"))) {
			this.#deleteSelected();
			return;
		}
		if (matchesKey(data, Key.tab)) {
			void this.#toggleScope();
			return;
		}
		if (matchesKey(data, Key.pageUp)) {
			this.#detailScroll = Math.max(0, this.#detailScroll - 5);
			this.#tui.requestRender();
			return;
		}
		if (matchesKey(data, Key.pageDown)) {
			this.#detailScroll += 5;
			this.#tui.requestRender();
			return;
		}
		this.#list.handleInput(data);
	}

	invalidate(): void {
		this.#list.invalidate();
	}

	dispose(): void {
		this.#closed = true;
	}

	/** Close the panel (the toggle shortcut and the host both use it). */
	close(): void {
		this.#close();
	}

	#close(): void {
		if (this.#closed) return;
		this.#closed = true;
		this.#done(undefined);
	}

	#keybar(): string {
		const theme = this.#theme;
		const parts = [
			`${theme.fg("muted", "ctrl+r")} refresh`,
			`${theme.fg("muted", "ctrl+s")} switch`,
			`${theme.fg("muted", "ctrl+d")} delete`,
			`${theme.fg("muted", "tab")} scope`,
			`${theme.fg("muted", "?")} keys`,
			`${theme.fg("muted", "alt+w")} close`,
		];
		return parts.join(theme.fg("dim", " · "));
	}

	#helpRows(width: number): string[] {
		const theme = this.#theme;
		const rows: string[] = [sectionHeader(theme, "KEYS", width), ""];
		for (const [key, description] of HELP_LINES) {
			rows.push(`${theme.fg("accent", key.padEnd(12))} ${theme.fg("muted", description)}`);
		}
		rows.push("");
		rows.push(theme.fg("dim", "press any key to go back"));
		return rows;
	}

	#listHeader(width: number): string {
		const projects = new Set(this.#rows.map(row => row.cwd || "(unknown project)")).size;
		const scope = this.#scope === "project" ? "this project" : `${projects} projects`;
		return metaHeader(this.#theme, "SESSIONS", `${this.#rows.length} · ${scope}`, width);
	}

	#detailHeader(width: number): string {
		const theme = this.#theme;
		const selected = this.#selected;
		if (!selected) {
			if (this.#selectedProject) {
				const marker = this.#currentProject === this.#selectedProject ? badge(theme, "current", "accent") : "";
				return fit(`${theme.bold(theme.fg("accent", this.#selectedProject))} ${marker}`.trim(), width);
			}
			return theme.fg("muted", "no session selected");
		}
		const markers: string[] = [];
		if (selected.current) markers.push(badge(theme, "current", "accent"));
		if (selected.derived) markers.push(badge(theme, "fork", "muted"));
		const title = theme.bold(theme.fg("text", selected.title));
		const head = markers.length > 0 ? `${title}  ${markers.join(" ")}` : title;
		return fit(head, Math.max(0, width));
	}

	#renderItem(context: SelectListRenderItemContext): readonly string[] {
		const theme = this.#theme;
		if (context.item.value.startsWith("group:")) {
			const project = context.item.value.slice("group:".length);
			const marker = this.#isOpen(project)
				? theme.fg("accent", theme.symbol("nav.collapse"))
				: theme.fg("muted", theme.symbol("nav.expand"));
			const current = project === this.#currentProject ? theme.fg("accent", " ●") : "";
			const label = context.selected ? theme.bold(theme.fg("accent", project)) : theme.fg("text", project);
			const count = theme.fg("muted", context.item.description ?? "");
			return [`${marker} ${label}${current} ${count}`];
		}
		const row = this.#rowByPath.get(context.item.value);
		if (!row) return [context.item.label];
		const cursor = context.selected ? theme.fg("accent", theme.symbol("nav.cursor")) : " ";
		const dot = theme.fg(statusColor(row.status), "•");
		const title = context.selected ? theme.bold(theme.fg("accent", row.title)) : theme.fg("text", row.title);
		const time = theme.fg("muted", row.modified > 0 ? timeAgo(row.modified) : "-");
		return [`${cursor} ${dot} ${rightAligned(title, time, Math.max(8, context.width - 4))}`];
	}

	#detailRows(width: number, maxRows: number): string[] {
		const theme = this.#theme;
		const rows: string[] = [];
		if (this.#loading && this.#rows.length === 0) {
			rows.push(theme.fg("muted", "Loading sessions…"));
		}
		if (this.#notice) {
			rows.push(theme.fg("error", this.#notice));
		}
		if (this.#confirming) {
			rows.push(theme.bold(theme.fg("warning", `Delete "${this.#confirming.title}"?`)));
			rows.push(theme.fg("muted", "  This removes the transcript and its artifacts."));
			rows.push(`${theme.fg("success", "y")} confirm   ${theme.fg("muted", "n")} cancel`);
			rows.push("");
		}
		const selected = this.#selected;
		if (!selected) {
			if (this.#selectedProject) rows.push(...this.#projectRows(this.#selectedProject, width));
			else if (rows.length === 0) rows.push(theme.fg("muted", "No session selected."));
			return rows.slice(0, maxRows);
		}
		rows.push(sectionHeader(theme, "SESSION", width));
		rows.push(
			...keyValueRows(
				theme,
				[
					["id", selected.id],
					["cwd", selected.cwd || "-"],
					["path", selected.path],
					["modified", selected.modified > 0 ? timeAgo(selected.modified) : "-"],
					["created", selected.created > 0 ? timestamp(new Date(selected.created)) : "-"],
					["size", fileSize(selected.size)],
					["turns", String(selected.turns)],
					["status", selected.status ?? "unknown"],
				],
				9,
				Math.max(0, width - 10),
			),
		);
		rows.push("");
		rows.push(sectionHeader(theme, "OUTLINE", width));
		if (this.#outline.items.length === 0) {
			rows.push(theme.fg("muted", "  no entries yet"));
		}
		const outlineRows: string[] = [];
		for (const item of this.#outline.items) {
			const label = OUTLINE_LABEL[item.kind].padEnd(5);
			const prefix =
				item.kind === "user"
					? theme.fg("accent", label)
					: item.kind === "assistant"
						? theme.fg("muted", label)
						: theme.fg("dim", label);
			const body = item.kind === "user" ? theme.fg("text", item.text) : theme.fg("muted", item.text);
			outlineRows.push(...wrapIndented(`${prefix} `, body, width));
		}
		if (this.#outline.truncated) outlineRows.push(theme.fg("dim", "  … more entries in this session"));
		// The outline scrolls on its own; the metadata above it stays put.
		const budget = Math.max(1, maxRows - rows.length);
		rows.push(...outlineRows.slice(this.#detailScroll, this.#detailScroll + budget));
		return rows.slice(0, maxRows);
	}

	/** Summary of a project group, shown when its header is selected. */
	#projectRows(project: string, width: number): string[] {
		const theme = this.#theme;
		const sessions = this.#rows.filter(row => (row.cwd || "(unknown project)") === project);
		const times = sessions.map(row => row.modified).filter(value => value > 0);
		const newest = times.length > 0 ? Math.max(...times) : 0;
		const oldest = times.length > 0 ? Math.min(...times) : 0;
		return [
			sectionHeader(theme, "project", width),
			...keyValueRows(
				theme,
				[
					["path", project],
					["sessions", String(sessions.length)],
					["newest", newest > 0 ? timeAgo(newest) : "-"],
					["oldest", oldest > 0 ? timeAgo(oldest) : "-"],
					["current", project === this.#currentProject ? "yes" : "no"],
				],
				9,
				Math.max(0, width - 10),
			),
			"",
			theme.fg("muted", "  enter opens the group, enter on a session switches to it"),
		];
	}

	#onSelection(item: SelectItem | undefined): void {
		const path = item?.value;
		if (!path) return;
		if (path.startsWith("group:")) {
			this.#selectedProject = path.slice("group:".length);
			this.#selected = undefined;
			this.#outlineFor = undefined;
			this.#outline = { items: [], truncated: false };
			this.#detailScroll = 0;
			this.#tui.requestRender();
			return;
		}
		this.#selectedProject = undefined;
		this.#selected = this.#rowByPath.get(path);
		this.#detailScroll = 0;
		if (this.#outlineFor === path) return;
		this.#outlineFor = path;
		this.#outline = { items: [], truncated: false };
		this.#tui.requestRender();
		void this.#loadOutline(path);
	}

	async #loadOutline(path: string): Promise<void> {
		const generation = this.#generation;
		const outline = await readSessionOutline(path);
		if (generation !== this.#generation || this.#outlineFor !== path) return;
		this.#outline = outline;
		this.#tui.requestRender();
	}

	async #reload(): Promise<void> {
		const generation = ++this.#generation;
		this.#loading = true;
		this.#notice = undefined;
		this.#outlineFor = undefined;
		this.#outline = { items: [], truncated: false };
		this.#detailScroll = 0;
		this.#tui.requestRender();
		try {
			const rows = await loadSessions({
				scope: this.#scope,
				sessionDir: this.#host.ctx.sessionManager.getSessionDir(),
				currentPath: this.#host.ctx.sessionManager.getSessionFile(),
			});
			if (generation !== this.#generation) return;
			this.#rows = rows;
			this.#rowByPath = new Map(rows.map(row => [row.path, row]));
			this.#flatItems = this.#buildItems(rows, true);
			const saved = await loadState();
			for (const [project, state] of Object.entries(saved.groups)) this.#groupState.set(project, state);
			this.#list.setItems(this.#buildItems(rows));
		} catch (error) {
			if (generation === this.#generation) {
				this.#notice = `Could not list sessions: ${error instanceof Error ? error.message : String(error)}`;
			}
		} finally {
			if (generation === this.#generation) {
				this.#loading = false;
				this.#tui.requestRender();
			}
		}
	}

	/**
	 * List rows grouped by project: a header per project, its sessions below
	 * it. The current project heads the list and starts expanded; the others
	 * stay collapsed until their header is opened.
	 */
	#buildItems(rows: SessionRow[], expandAll = false): SelectItem[] {
		const items: SelectItem[] = [];
		const byProject = new Map<string, SessionRow[]>();
		for (const row of rows) {
			const project = row.cwd || "(unknown project)";
			const sessions = byProject.get(project);
			if (sessions) sessions.push(row);
			else byProject.set(project, [row]);
		}
		const projects = [...byProject.keys()].sort((left, right) => {
			if (left === this.#currentProject) return -1;
			if (right === this.#currentProject) return 1;
			return left.localeCompare(right);
		});
		for (const project of projects) {
			const sessions = byProject.get(project) ?? [];
			items.push({
				value: `group:${project}`,
				label: project,
				description: `${sessions.length} sessions`,
				searchText: project,
			});
			if (!expandAll && !this.#isOpen(project)) continue;
			for (const row of sessions) items.push(this.#sessionItem(row));
		}
		return items;
	}

	/** Whether a project group shows its sessions; the current project is open by default. */
	#isOpen(project: string): boolean {
		const state = this.#groupState.get(project);
		if (state) return state === "open";
		return project === this.#currentProject;
	}

	/** Expand or collapse a project group and rebuild the list. */
	#toggleGroup(project: string): void {
		this.#groupState.set(project, this.#isOpen(project) ? "closed" : "open");
		this.#list.setItems(this.#buildItems(this.#rows));
		this.#tui.requestRender();
		void this.#persistGroups();
	}

	/** Remember which project groups were opened or closed. */
	async #persistGroups(): Promise<void> {
		const groups: Record<string, "open" | "closed"> = {};
		for (const [project, state] of this.#groupState) groups[project] = state;
		const current = await loadState();
		await saveState({ ...current, groups });
	}

	/**
	 * Filter sessions by title and projects by path: a query that names a
	 * project keeps every session of that project.
	 */
	#filterItems(items: readonly SelectItem[], query: string): readonly SelectItem[] {
		if (query.trim().length === 0) return items;
		const needle = query.toLowerCase();
		// Filtering flattens the groups: a query that names a project reveals
		// its sessions even when the group is collapsed in the list.
		const searchable = this.#flatItems;
		const projectOf = new Map<string, string>();
		let currentProject: string | undefined;
		for (const item of searchable) {
			if (item.value.startsWith("group:")) {
				currentProject = item.value.slice("group:".length);
				continue;
			}
			if (currentProject) projectOf.set(item.value, currentProject);
		}
		const matchedProjects = new Set<string>();
		for (const item of searchable) {
			if (!item.value.startsWith("group:")) continue;
			const project = item.value.slice("group:".length);
			if (project.toLowerCase().includes(needle)) matchedProjects.add(project);
		}
		const matchedSessions = new Set<string>();
		for (const item of searchable) {
			if (item.value.startsWith("group:")) continue;
			const haystack = `${item.label} ${item.searchText ?? ""}`.toLowerCase();
			if (haystack.includes(needle)) matchedSessions.add(item.value);
		}
		return searchable
			.filter(item => {
				if (item.value.startsWith("group:")) {
					const project = item.value.slice("group:".length);
					return matchedProjects.has(project) || this.#sessionsOf(project, matchedSessions).length > 0;
				}
				if (matchedProjects.has(projectOf.get(item.value) ?? "")) return true;
				return matchedSessions.has(item.value);
			})
			.map(item => {
				// A group header counts the sessions that survived the filter,
				// not the ones it holds in total.
				if (!item.value.startsWith("group:")) return item;
				const project = item.value.slice("group:".length);
				const count = this.#sessionsOf(project, matchedSessions).length;
				return { ...item, description: `${count} session${count === 1 ? "" : "s"}` };
			});
	}

	/** Sessions of a project that survived the filter. */
	#sessionsOf(project: string, matched: Set<string>): SessionRow[] {
		return this.#rows.filter(row => (row.cwd || "(unknown project)") === project && matched.has(row.path));
	}

	#sessionItem(row: SessionRow): SelectItem {
		return {
			value: row.path,
			label: row.title,
			description: `${row.cwd} · ${timeAgo(row.modified)} · ${row.status ?? "unknown"}`,
			searchText: `${row.title} ${row.cwd} ${row.id}`,
		};
	}

	async #toggleScope(): Promise<void> {
		this.#scope = this.#scope === "project" ? "all" : "project";
		await this.#reload();
	}

	async #switchTo(path: string | undefined): Promise<void> {
		if (!path) return;
		const row = this.#rowByPath.get(path);
		if (!row) return;
		if (row.current) {
			this.#notice = "That is the session you are already running.";
			this.#tui.requestRender();
			return;
		}
		const switchSession = this.#host.switchSession;
		if (!switchSession) {
			this.#notice = "Switching sessions needs the /workbench command (shortcuts cannot switch).";
			this.#tui.requestRender();
			return;
		}
		const result = await switchSession.call(this.#host, path);
		if (result.cancelled) {
			this.#notice = "Switch cancelled.";
			this.#tui.requestRender();
			return;
		}
		this.#close();
	}

	#deleteSelected(): void {
		const path = this.#list.getSelectedItem()?.value;
		if (!path) return;
		const row = this.#rowByPath.get(path);
		if (!row) return;
		if (row.current) {
			this.#notice = "The running session cannot be deleted from here.";
			this.#tui.requestRender();
			return;
		}
		if (!this.#host.dropSession) {
			this.#notice = "Deleting sessions needs the /workbench command.";
			this.#tui.requestRender();
			return;
		}
		this.#confirming = { path, title: row.title };
		this.#tui.requestRender();
	}

	#handleConfirmInput(data: string): void {
		if (data === "y" || data === "Y") {
			const target = this.#confirming;
			this.#confirming = undefined;
			if (target) void this.#deleteSession(target.path);
			return;
		}
		if (data === "n" || data === "N" || matchesKey(data, Key.escape)) {
			this.#confirming = undefined;
			this.#tui.requestRender();
		}
	}

	async #deleteSession(path: string): Promise<void> {
		const dropSession = this.#host.dropSession;
		if (!dropSession) return;
		try {
			await dropSession.call(this.#host, path);
		} catch (error) {
			this.#notice = `Delete failed: ${error instanceof Error ? error.message : String(error)}`;
			this.#tui.requestRender();
			return;
		}
		await this.#reload();
	}
}
