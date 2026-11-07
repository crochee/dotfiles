/**
 * Files page.
 *
 * The file tree is nvim-tree's: the page hands the terminal to nvim with the
 * tree open at the project root. What stays here is the quick-open index
 * (a path search across the project), plus new-file and delete.
 */
import { mkdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { Key, matchesKey } from "@oh-my-pi/pi-tui";
import { fit, metaHeader } from "../../ui/chrome";
import { launchEditor, editorName } from "../launch";
import { ListView } from "../list";
import { detectNvimTree, launchNvimTree, type NvimTreeStatus } from "../nvim-tree";
import { searchFiles, type SearchMatch } from "../search";
import { loadState, saveState } from "../../state";
import type { EditorKey, EditorTab, EditorTabContext } from "../tab";

type Mode = "browse" | "filter" | "new" | "delete" | "confirm-delete";

const BROWSE_KEYS: readonly EditorKey[] = [
	{ key: "enter / t / e", short: "enter tree", description: "open the file tree in nvim (nvim-tree)" },
	{ key: "/", short: "/ search", description: "quick open a file by path" },
	{ key: "n", short: "n new", description: "create a file and open it" },
	{ key: "d", short: "d delete", description: "delete a file" },
	{ key: "h", short: "h hidden", description: "list dotfiles in the quick open" },
	{ key: "r", short: "r recheck", description: "check again for nvim-tree" },
];

const FILTER_KEYS: readonly EditorKey[] = [
	{ key: "enter", short: "enter open", description: "open the selected file" },
	{ key: "ctrl+d", short: "ctrl+d delete", description: "delete the selected file" },
	{ key: "esc", short: "esc clear", description: "clear the query" },
];

const PATH_KEYS: readonly EditorKey[] = [
	{ key: "enter", short: "enter ok", description: "confirm" },
	{ key: "esc", short: "esc cancel", description: "cancel" },
];

/** True for a chunk of plain text, which a paste or a fast typist produces. */
function isPrintableText(data: string): boolean {
	if (data.length === 0) return false;
	if (data.startsWith("\x1b")) return false;
	for (const character of data) {
		if (character < " " || character === "\x7f") return false;
	}
	return true;
}

export class FilesTab implements EditorTab {
	readonly id = "files";
	readonly label = "Files";
	readonly #context: EditorTabContext;
	readonly #root: string;
	readonly #list = new ListView<SearchMatch>();
	#status: NvimTreeStatus | undefined;
	#mode: Mode = "browse";
	#query = "";
	#pending = "";
	#showHidden = false;
	#searching = false;
	#message: string | undefined;
	/** Guards against a slow search overwriting the results of a newer one. */
	#searchGeneration = 0;
	/** The same guard for the nvim probe. */
	#probeGeneration = 0;
	/** The nvim probe runs once; "r" asks for another. */
	#probed = false;

	constructor(context: EditorTabContext) {
		this.#context = context;
		this.#root = context.host.ctx.cwd;
	}

	activate(): void {
		if (this.#probed) return;
		this.#probed = true;
		void this.#start();
	}

	capturesKeys(): boolean {
		return this.#mode !== "browse";
	}

	keys(): readonly EditorKey[] {
		if (this.#mode === "filter") return FILTER_KEYS;
		if (this.#mode === "new" || this.#mode === "delete") return PATH_KEYS;
		return BROWSE_KEYS;
	}

	render(width: number, height: number): readonly string[] {
		const theme = this.#context.theme;
		const rows: string[] = [];

		if (this.#mode === "confirm-delete") {
			// The prompt stays at the top: the list scrolls, the prompt must not.
			rows.push(theme.fg("error", `delete ${this.#pending}? y/n`));
		} else if (this.#message) {
			rows.push(theme.fg("error", this.#message));
		} else if (this.#mode === "filter") {
			rows.push(metaHeader(theme, "FILES", `${this.#list.items.length} matches`, width));
		} else {
			rows.push(metaHeader(theme, "FILES", this.#root, width));
		}
		rows.push("");

		if (this.#mode === "filter") {
			rows.push(...this.#matchRows(width, height));
		} else if (this.#mode === "browse") {
			rows.push(...this.#browseRows(width, height));
		}

		if (this.#mode === "filter") {
			rows.push(theme.fg("accent", `/${this.#query}`));
		} else if (this.#mode === "new") {
			rows.push(theme.fg("accent", `new file: ${this.#pending}`));
		} else if (this.#mode === "delete") {
			rows.push(theme.fg("accent", `delete file: ${this.#pending}`));
		}
		return rows;
	}

	handleInput(data: string): boolean {
		switch (this.#mode) {
			case "filter":
				return this.#filterInput(data);
			case "new":
				return this.#pathInput(data, "new");
			case "delete":
				return this.#pathInput(data, "delete");
			case "confirm-delete":
				return this.#confirmInput(data);
			default:
				return this.#browseInput(data);
		}
	}

	/** Keys that act on the page as a whole. */
	#browseInput(data: string): boolean {
		if (matchesKey(data, Key.enter) || data === "t" || data === "e") {
			void this.#openTree();
			return true;
		}
		if (data === "/") {
			this.#mode = "filter";
			this.#query = "";
			this.#list.reset([]);
			void this.#search();
			return true;
		}
		if (data === "n") {
			this.#mode = "new";
			this.#pending = "";
			return true;
		}
		if (data === "d") {
			this.#mode = "delete";
			this.#pending = "";
			return true;
		}
		if (data === "h") {
			this.#showHidden = !this.#showHidden;
			this.#context.refresh();
			void this.#persistHidden();
			return true;
		}
		if (data === "r") {
			void this.#detect();
			return true;
		}
		return false;
	}

	/** Typing in the quick-open filter. */
	#filterInput(data: string): boolean {
		// Ctrl+D deletes a match; a plain "d" would type into the filter.
		if (matchesKey(data, Key.ctrl("d"))) {
			const match = this.#list.selected;
			if (match) {
				this.#mode = "confirm-delete";
				this.#pending = match.relPath;
			}
			this.#context.refresh();
			return true;
		}
		if (matchesKey(data, Key.escape)) {
			this.#mode = "browse";
			this.#query = "";
			this.#list.reset([]);
			this.#context.refresh();
			return true;
		}
		if (matchesKey(data, Key.enter)) {
			const match = this.#list.selected;
			if (match) void this.#openFile(match);
			return true;
		}
		if (matchesKey(data, Key.backspace)) {
			this.#query = this.#query.slice(0, -1);
			void this.#search();
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
		if (isPrintableText(data)) {
			this.#query += data;
			this.#list.reset([]);
			void this.#search();
			return true;
		}
		return true;
	}

	/** Typing a path for a new file or a deletion. */
	#pathInput(data: string, kind: "new" | "delete"): boolean {
		if (matchesKey(data, Key.escape)) {
			this.#mode = "browse";
			this.#pending = "";
			this.#context.refresh();
			return true;
		}
		if (matchesKey(data, Key.enter)) {
			const target = this.#pending.trim();
			this.#mode = kind === "new" ? "browse" : "confirm-delete";
			this.#pending = kind === "new" ? "" : target;
			if (kind === "new" && target.length > 0) void this.#createFile(target);
			this.#context.refresh();
			return true;
		}
		if (matchesKey(data, Key.backspace)) {
			this.#pending = this.#pending.slice(0, -1);
			this.#context.refresh();
			return true;
		}
		if (isPrintableText(data)) {
			this.#pending += data;
			this.#context.refresh();
			return true;
		}
		return true;
	}

	/** Confirming a delete. */
	#confirmInput(data: string): boolean {
		const target = this.#pending;
		this.#mode = "browse";
		this.#pending = "";
		if (data === "y") void this.#delete(target);
		this.#context.refresh();
		return true;
	}

	/** The matches of the quick open. */
	#matchRows(width: number, height: number): string[] {
		const theme = this.#context.theme;
		if (this.#searching) return [theme.fg("muted", "  searching…")];
		if (this.#list.items.length === 0) return [theme.fg("muted", "  (no match)")];
		const rows: string[] = [];
		const { rows: visible, offset } = this.#list.window(Math.max(1, height - 4));
		visible.forEach((match, position) => {
			const selected = this.#list.isSelected(offset, position);
			const cursor = selected ? theme.fg("accent", theme.symbol("nav.cursor")) : " ";
			const label = selected ? theme.bold(theme.fg("accent", match.relPath)) : theme.fg("text", match.relPath);
			rows.push(fit(`${cursor} ${label}`, width));
		});
		return rows;
	}

	/** The page as it looks without a query. */
	#browseRows(width: number, height: number): string[] {
		const theme = this.#context.theme;
		const status = this.#status;
		const rows: string[] = [];
		for (const entry of this.keys()) {
			if (rows.length >= Math.max(1, height - 4)) break;
			rows.push(
				fit(`${theme.fg("accent", entry.key.padEnd(14))} ${theme.fg("muted", entry.description)}`, width),
			);
		}
		rows.push("");
		if (status) {
			const color = status.plugin ? "success" : status.nvim ? "warning" : "error";
			rows.push(theme.fg(color, `  ${status.detail}`));
			if (!status.plugin && status.nvim) {
				rows.push(theme.fg("muted", "  install: lazy add nvim-tree/nvim-tree.nvim"));
			}
		} else {
			rows.push(theme.fg("muted", "  checking nvim…"));
		}
		return rows;
	}

	/** Hand the terminal to nvim with nvim-tree open. */
	async #openTree(): Promise<void> {
		this.#message = undefined;
		const status = this.#status ?? (await detectNvimTree(this.#context.exec));
		this.#status = status;
		if (!status.nvim) {
			this.#message = "nvim was not found on the PATH";
			this.#context.refresh();
			return;
		}
		if (!status.plugin) {
			this.#message = "nvim-tree is not installed for this nvim";
			this.#context.refresh();
			return;
		}
		this.#context.notify(`opening ${this.#root} in nvim-tree…`);
		const result = await launchNvimTree(this.#context.tui, this.#root);
		if (result.error) {
			this.#message = result.error;
			this.#context.refresh();
			return;
		}
		this.#context.refresh();
	}

	/** Open one file in the editor. */
	async #openFile(match: SearchMatch): Promise<void> {
		this.#message = undefined;
		this.#context.notify(`opening ${match.relPath} in ${editorName()}…`);
		const result = await launchEditor(this.#context.tui, match.path);
		if (result.error) {
			this.#message = result.error;
			this.#context.refresh();
		}
	}

	/** Create a file (and its parents) and open it. */
	async #createFile(target: string): Promise<void> {
		const full = path.resolve(this.#root, target);
		try {
			await mkdir(path.dirname(full), { recursive: true });
			await writeFile(full, "", { flag: "a" });
		} catch (error) {
			this.#message = `cannot create ${target}: ${error instanceof Error ? error.message : String(error)}`;
			this.#context.refresh();
			return;
		}
		await this.#openFile({ relPath: target, path: full });
	}

	/** Delete a file or directory. */
	async #delete(target: string): Promise<void> {
		const full = path.resolve(this.#root, target);
		const relative = path.relative(this.#root, full);
		if (relative.length === 0 || relative.startsWith("..") || path.isAbsolute(relative)) {
			this.#message = "refusing to delete outside the project";
			this.#context.refresh();
			return;
		}
		try {
			await rm(full, { recursive: true, force: true });
		} catch (error) {
			this.#message = `cannot delete ${target}: ${error instanceof Error ? error.message : String(error)}`;
			this.#context.refresh();
			return;
		}
		this.#message = `deleted ${target}`;
		this.#context.refresh();
	}

	/** Search the project for paths matching the filter. */
	async #search(): Promise<void> {
		const generation = ++this.#searchGeneration;
		this.#searching = true;
		this.#context.refresh();
		const result = await searchFiles(
			this.#root,
			this.#query,
			{ showHidden: this.#showHidden },
			this.#context.exec,
		);
		if (generation !== this.#searchGeneration) return;
		this.#list.reset(result.matches);
		this.#searching = false;
		this.#context.refresh();
	}

	/** Restore the saved switch, then look for nvim-tree. */
	async #start(): Promise<void> {
		const saved = await loadState();
		if (saved.editor) this.#showHidden = saved.editor.showHidden;
		await this.#detect();
	}

	/** Ask nvim whether it can load nvim-tree. */
	async #detect(): Promise<void> {
		const generation = ++this.#probeGeneration;
		const status = await detectNvimTree(this.#context.exec);
		if (generation !== this.#probeGeneration) return;
		this.#status = status;
		this.#context.refresh();
	}

	/** Remember whether the quick open lists dotfiles. */
	async #persistHidden(): Promise<void> {
		const current = await loadState();
		await saveState({ ...current, editor: { showHidden: this.#showHidden } });
	}
}
