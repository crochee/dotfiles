/**
 * The editor surface: a full-screen view over the running session.
 *
 * It paints on the terminal's alternate screen, so the conversation on the
 * normal screen is left untouched and the session keeps working while the
 * surface is open. Esc hands the terminal back to the prompt.
 */
import { type Component, Key, type TUI, matchesKey } from "@oh-my-pi/pi-tui";
import type { Theme } from "@oh-my-pi/pi-tui/theme";
import { fit, padTo, sectionHeader } from "../ui/chrome";
import type { SessionHost } from "../sessions/host";
import type { EditorKey, EditorTab, EditorTabContext, EditorTabDefinition, ExecRunner } from "./tab";

export interface EditorPanelOptions {
	host: SessionHost;
	tui: TUI;
	theme: Theme;
	done: (result: undefined) => void;
	exec: ExecRunner;
	tabDefinitions: readonly EditorTabDefinition[];
}

/** Gap between tab labels in the strip. */
const TAB_GAP = 3;

/** The keys the surface itself binds, on top of the page's own. */
const SURFACE_KEYS: readonly EditorKey[] = [
	{ key: "tab / shift+tab", short: "tab page", description: "next / previous page" },
	{ key: "1 - 9", short: "1-9 page", description: "jump to a page" },
	{ key: "?", short: "? keys", description: "toggle this help" },
	{ key: "esc", short: "esc close", description: "close the surface" },
];

export class EditorPanel implements Component {
	readonly #host: SessionHost;
	readonly #tui: TUI;
	readonly #theme: Theme;
	readonly #done: (result: undefined) => void;
	readonly #definitions: readonly EditorTabDefinition[];
	/** Pages are built when they are first shown; the tab strip needs no instance. */
	readonly #tabs: (EditorTab | undefined)[];
	readonly #context: EditorTabContext;
	#index = 0;
	#message: string | undefined;
	#closed = false;
	#help = false;

	constructor(options: EditorPanelOptions) {
		this.#host = options.host;
		this.#tui = options.tui;
		this.#theme = options.theme;
		this.#done = options.done;
		this.#definitions = options.tabDefinitions;
		this.#tabs = options.tabDefinitions.map(() => undefined);
		this.#context = {
			host: options.host,
			theme: options.theme,
			tui: options.tui,
			exec: options.exec,
			refresh: () => this.#tui.requestRender(),
			notify: message => {
				this.#message = message;
				this.#tui.requestRender();
			},
			close: () => this.#close(),
			sessionState: () => (this.#host.ctx.isIdle() ? "idle" : "working"),
		};
		// The page on screen loads right away; the others wait for their turn.
		this.#tab(0)?.activate?.();
	}

	render(width: number): readonly string[] {
		const total = Math.max(24, width);
		const rows: string[] = [];
		const bodyHeight = Math.max(1, this.#tui.terminal.rows - 4);
		rows.push(this.#header(total));
		rows.push(this.#tabStrip(total));
		const body = this.#help
			? this.#helpRows(total, bodyHeight)
			: (this.#tab(this.#index)?.render(total, bodyHeight) ?? []);
		for (let index = 0; index < bodyHeight; index++) {
			rows.push(padTo(body[index] ?? "", total));
		}
		rows.push(this.#keybar(total));
		return rows;
	}

	handleInput(data: string): void {
		if (this.#closed) return;
		// Any key press retires the last message; it described a moment that
		// has passed.
		this.#message = undefined;
		const tab = this.#tab(this.#index);

		// A page that owns the keyboard (a text prompt) gets everything first.
		if (tab?.capturesKeys?.() && tab.handleInput?.(data)) {
			this.#tui.requestRender();
			return;
		}
		if (matchesKey(data, Key.ctrl("c")) || matchesKey(data, Key.alt("b"))) {
			this.#close();
			return;
		}
		if (matchesKey(data, Key.escape)) {
			// The page may want the escape (to clear its filter) before the
			// surface gives up the terminal.
			if (tab?.handleInput?.(data)) {
				this.#tui.requestRender();
				return;
			}
			this.#close();
			return;
		}
		if (matchesKey(data, Key.tab)) {
			this.#select(this.#index + 1);
			return;
		}
		if (matchesKey(data, Key.shift("tab"))) {
			this.#select(this.#index - 1);
			return;
		}
		if (this.#help) {
			this.#help = false;
			this.#tui.requestRender();
			return;
		}
		if (data === "?") {
			this.#help = true;
			this.#tui.requestRender();
			return;
		}
		// The page jump is the surface's own key, so it is claimed before the
		// page gets a chance to swallow the digit as text.
		if (/^[1-9]$/.test(data)) {
			const target = Number.parseInt(data, 10) - 1;
			if (target < this.#definitions.length) this.#select(target);
			return;
		}
		if (tab?.handleInput?.(data)) {
			this.#tui.requestRender();
			return;
		}
	}

	invalidate(): void {
		// Pages own their caches; nothing to invalidate here.
	}

	dispose(): void {
		this.#closed = true;
	}

	/** Close the surface and hand the terminal back to the prompt. */
	close(): void {
		this.#close();
	}

	#close(): void {
		if (this.#closed) return;
		this.#closed = true;
		this.#done(undefined);
	}

	/** The page at `index`, built on first use. */
	#tab(index: number): EditorTab | undefined {
		const existing = this.#tabs[index];
		if (existing) return existing;
		const definition = this.#definitions[index];
		if (!definition) return undefined;
		const tab = definition.create(this.#context);
		this.#tabs[index] = tab;
		return tab;
	}

	/** The header: where we are and what the session is doing. */
	#header(width: number): string {
		const theme = this.#theme;
		const cwd = this.#host.ctx.cwd;
		const home = process.env.HOME ?? "";
		const short = home && cwd.startsWith(home) ? cwd.slice(home.length) || cwd : cwd;
		const state = this.#host.ctx.isIdle() ? "idle" : "working";
		const color = state === "idle" ? "muted" : "success";
		const parts = [theme.fg("accent", short), theme.fg(color, `session ${state}`)];
		return fit(`${theme.fg("border", "▌")} ${parts.join(theme.fg("dim", " · "))}`, width);
	}

	/** Tab labels with the active one highlighted. */
	#tabStrip(width: number): string {
		const theme = this.#theme;
		return fit(
			this.#definitions
				.map((definition, index) =>
					index === this.#index ? theme.bold(definition.label) : theme.fg("muted", definition.label),
				)
				.join(" ".repeat(TAB_GAP)),
			width,
		);
	}

	#keybar(width: number): string {
		const theme = this.#theme;
		if (this.#message) return fit(theme.fg("accent", this.#message), width);
		const hints = [...this.#pageKeys(), ...SURFACE_KEYS].map(entry => entry.short ?? entry.key);
		return fit(hints.map(hint => theme.fg("muted", hint)).join(theme.fg("dim", " · ")), width);
	}

	#helpRows(width: number, height: number): string[] {
		const theme = this.#theme;
		const rows: string[] = [sectionHeader(theme, "PAGE", width), ""];
		const pageRows = this.#pageKeys();
		if (pageRows.length === 0) {
			rows.push(theme.fg("muted", "this page has no keys of its own"));
		} else {
			for (const entry of pageRows) {
				if (rows.length >= height - 4) break;
				rows.push(fit(`${theme.fg("accent", entry.key.padEnd(16))} ${theme.fg("muted", entry.description)}`, width));
			}
		}
		rows.push("");
		rows.push(sectionHeader(theme, "SURFACE", width));
		for (const entry of SURFACE_KEYS) {
			if (rows.length >= height - 1) break;
			rows.push(fit(`${theme.fg("accent", entry.key.padEnd(16))} ${theme.fg("muted", entry.description)}`, width));
		}
		return rows;
	}

	/** The keys of the page on screen. */
	#pageKeys(): readonly EditorKey[] {
		return this.#tab(this.#index)?.keys?.() ?? [];
	}

	#select(index: number): void {
		if (this.#definitions.length === 0) return;
		const next = ((index % this.#definitions.length) + this.#definitions.length) % this.#definitions.length;
		if (next === this.#index) return;
		this.#index = next;
		this.#tab(next)?.activate?.();
		this.#tui.requestRender();
	}
}
