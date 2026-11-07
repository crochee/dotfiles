/** Sessions page: recent sessions of the project (or of every project). */
import { Key, matchesKey } from "@oh-my-pi/pi-tui";
import { metaHeader, rightAligned } from "../../ui/chrome";
import { statusColor, timeAgo } from "../../ui/format";
import { loadSessions, type SessionRow, type SessionScope } from "../../sessions/source";
import { ListView } from "../list";
import { applyFilterKey, matchesFilter } from "../filter";
import type { EditorKey, EditorTab, EditorTabContext } from "../tab";

const KEYS: readonly EditorKey[] = [
	{ key: "type", short: "type filter", description: "narrow the list by title or project" },
	{ key: "↑ ↓", short: "↑↓ move", description: "move in the list" },
	{ key: "enter", short: "enter switch", description: "switch to the selected session" },
	{ key: "t", short: "t scope", description: "toggle scope: this project / all projects" },
	{ key: "r", short: "r reload", description: "reload the list" },
];

export class SessionsTab implements EditorTab {
	readonly id = "sessions";
	readonly label = "Sessions";
	readonly #context: EditorTabContext;
	/** The rows on screen: the sessions that survived the filter. */
	readonly #list = new ListView<SessionRow>();
	#rows: SessionRow[] = [];
	#scope: SessionScope = "project";
	#loading = false;
	#message: string | undefined;
	#query = "";

	constructor(context: EditorTabContext) {
		this.#context = context;
	}

	activate(): void {
		void this.#load();
	}

	/**
	 * True while a filter is being typed: the page then owns the digits too,
	 * so a session title can be searched for.
	 */
	capturesKeys(): boolean {
		return this.#query.length > 0;
	}

	keys(): readonly EditorKey[] {
		return KEYS;
	}

	render(width: number, height: number): readonly string[] {
		const theme = this.#context.theme;
		const rows: string[] = [];
		const scope = this.#scope === "project" ? "this project" : "all projects";
		rows.push(
			metaHeader(
				theme,
				"SESSIONS",
				this.#query.length > 0
					? `${this.#list.items.length}/${this.#rows.length} · ${this.#query}`
					: `${this.#rows.length} · ${scope}`,
				width,
			),
		);
		rows.push("");
		if (this.#loading) rows.push(theme.fg("muted", "Loading…"));
		if (this.#message) rows.push(theme.fg("error", this.#message));
		if (this.#list.items.length === 0 && !this.#loading) {
			rows.push(theme.fg("muted", this.#query.length > 0 ? "  (no match)" : "  (no sessions)"));
		}
		const budget = Math.max(1, height - rows.length);
		const { rows: visible, offset } = this.#list.window(budget);
		visible.forEach((row, position) => {
			const selected = this.#list.isSelected(offset, position);
			const cursor = selected ? theme.fg("accent", theme.symbol("nav.cursor")) : " ";
			const dot = theme.fg(statusColor(row.status), "•");
			const title = selected ? theme.bold(theme.fg("accent", row.title)) : theme.fg("text", row.title);
			const time = theme.fg("muted", row.modified > 0 ? timeAgo(row.modified) : "-");
			rows.push(`${cursor} ${dot} ${rightAligned(title, time, Math.max(8, width - 4))}`);
		});
		return rows;
	}

	handleInput(data: string): boolean {
		const filter = applyFilterKey(this.#query, data);
		if (filter.consumed) {
			this.#query = filter.query;
			this.#applyFilter();
			return true;
		}
		if (matchesKey(data, Key.up)) {
			this.#list.move(-1);
			this.#context.refresh();
			return true;
		}
		if (matchesKey(data, Key.down)) {
			this.#list.move(1);
			this.#context.refresh();
			return true;
		}
		if (matchesKey(data, Key.enter)) {
			const row = this.#list.selected;
			if (row && !row.current) void this.#switchTo(row);
			return true;
		}
		if (data === "t") {
			this.#scope = this.#scope === "project" ? "all" : "project";
			this.#list.reset([]);
			void this.#load();
			return true;
		}
		if (data === "r") {
			void this.#load();
			return true;
		}
		return false;
	}

	/** Show the sessions that match the filter. */
	#applyFilter(): void {
		const needle = this.#query.toLowerCase();
		const visible =
			needle.length === 0
				? this.#rows
				: this.#rows.filter(row => matchesFilter(this.#query, `${row.title} ${row.cwd}`));
		this.#list.reset(visible);
		this.#context.refresh();
	}

	async #switchTo(row: SessionRow): Promise<void> {
		const switchSession = this.#context.host.switchSession;
		if (!switchSession) {
			this.#message = "Switching sessions needs the /workbench command.";
			this.#context.refresh();
			return;
		}
		const result = await switchSession.call(this.#context.host, row.path);
		if (result.cancelled) {
			this.#message = "Switch cancelled.";
			this.#context.refresh();
			return;
		}
		this.#context.close();
	}

	async #load(): Promise<void> {
		this.#loading = true;
		this.#message = undefined;
		this.#context.refresh();
		try {
			this.#rows = await loadSessions({
				scope: this.#scope,
				sessionDir: this.#context.host.ctx.sessionManager.getSessionDir(),
				currentPath: this.#context.host.ctx.sessionManager.getSessionFile(),
			});
			this.#applyFilter();
		} catch (error) {
			this.#rows = [];
			this.#list.reset([]);
			this.#message = error instanceof Error ? error.message : String(error);
		}
		this.#loading = false;
		this.#context.refresh();
	}
}
