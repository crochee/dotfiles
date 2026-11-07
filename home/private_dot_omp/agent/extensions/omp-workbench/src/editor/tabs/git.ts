/** Git page: branch, working tree, recent commits, staging. */
import { Key, matchesKey } from "@oh-my-pi/pi-tui";
import { fit, metaHeader, rightAligned } from "../../ui/chrome";
import { ListView } from "../list";
import { readGitSnapshot, type GitSnapshot, type GitStatusEntry } from "../git";
import type { EditorKey, EditorTab, EditorTabContext } from "../tab";

type FileKind = "staged" | "changed" | "untracked";

interface GitFile {
	path: string;
	kind: FileKind;
	letter: string;
}

const KEYS: readonly EditorKey[] = [
	{ key: "↑ ↓", short: "↑↓ move", description: "move in the list" },
	{ key: "enter", short: "enter stage", description: "stage the file, or unstage it" },
	{ key: "r", short: "r reload", description: "reload the repository state" },
];

function groupOf(entry: GitStatusEntry): FileKind {
	if (entry.index === "?" && entry.worktree === "?") return "untracked";
	if (entry.index !== " " && entry.index !== "") return "staged";
	return "changed";
}

const KIND_ORDER: readonly FileKind[] = ["staged", "changed", "untracked"];

export class GitTab implements EditorTab {
	readonly id = "git";
	readonly label = "Git";
	readonly #context: EditorTabContext;
	readonly #list = new ListView<GitFile>();
	#snapshot: GitSnapshot | undefined;
	#loading = false;
	#message: string | undefined;

	constructor(context: EditorTabContext) {
		this.#context = context;
	}

	activate(): void {
		void this.#load();
	}

	keys(): readonly EditorKey[] {
		return KEYS;
	}

	render(width: number, height: number): readonly string[] {
		const theme = this.#context.theme;
		const rows: string[] = [];
		const snapshot = this.#snapshot;
		if (this.#loading && !snapshot) rows.push(theme.fg("muted", "Loading…"));
		if (this.#message) rows.push(theme.fg("error", this.#message));
		if (!snapshot) {
			rows.push(theme.fg("muted", "No git state yet."));
			return rows;
		}
		if (!snapshot.isRepo) {
			rows.push(theme.fg("muted", snapshot.error ?? "Not a git repository."));
			return rows;
		}
		const tracking = snapshot.upstream ? theme.fg("muted", `→ ${snapshot.upstream}`) : "";
		const counts = [
			snapshot.ahead > 0 ? theme.fg("warning", `↑${snapshot.ahead}`) : undefined,
			snapshot.behind > 0 ? theme.fg("warning", `↓${snapshot.behind}`) : undefined,
		].filter(Boolean);
		const branch = `${theme.symbol("icon.branch")} ${theme.bold(theme.fg("accent", snapshot.branch || "HEAD"))}`;
		rows.push(fit(`${branch} ${tracking} ${counts.join(" ")}`, width));
		rows.push("");

		const budget = Math.max(1, height - rows.length);
		const { rows: visible, offset } = this.#list.window(budget);
		let lastKind: FileKind | undefined;
		visible.forEach((file, position) => {
			if (file.kind !== lastKind) {
				lastKind = file.kind;
				const count = this.#list.items.filter(item => item.kind === file.kind).length;
				rows.push(metaHeader(theme, file.kind.toUpperCase(), `${count}`, width));
			}
			const selected = this.#list.isSelected(offset, position);
			const cursor = selected ? theme.fg("accent", theme.symbol("nav.cursor")) : " ";
			const color = file.letter === "?" ? "muted" : file.letter === "A" ? "success" : "warning";
			const letter = theme.fg(color, file.letter);
			const label = selected ? theme.bold(theme.fg("accent", file.path)) : theme.fg("text", file.path);
			rows.push(`${cursor} ${letter} ${fit(label, Math.max(0, width - 4))}`);
		});
		if (this.#list.items.length === 0) {
			rows.push(theme.fg("success", "  working tree clean"));
		}
		if (snapshot.commits.length > 0) {
			rows.push("");
			rows.push(metaHeader(theme, "COMMITS", `${snapshot.commits.length}`, width));
			for (const commit of snapshot.commits.slice(0, 8)) {
				rows.push(
					rightAligned(
						theme.fg("text", commit.subject),
						theme.fg("muted", commit.hash.slice(0, 7)),
						width,
					),
				);
			}
		}
		return rows.slice(0, Math.max(1, height));
	}

	handleInput(data: string): boolean {
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
			const file = this.#list.selected;
			if (file) void this.#toggleStage(file);
			return true;
		}
		if (data === "r") {
			void this.#load();
			return true;
		}
		return false;
	}

	/** Stage an unstaged file, or unstage a staged one. */
	async #toggleStage(file: GitFile): Promise<void> {
		const root = this.#snapshot?.root;
		if (!root) return;
		const args = file.kind === "staged" ? ["reset", "-q", "--", file.path] : ["add", "--", file.path];
		const result = await this.#context.exec("git", args, { cwd: root });
		if (result.code !== 0) {
			this.#message = result.stderr.trim() || `git ${args[0]} failed`;
			this.#context.refresh();
			return;
		}
		await this.#load();
	}

	async #load(): Promise<void> {
		this.#loading = true;
		this.#context.refresh();
		const snapshot = await readGitSnapshot(this.#context.exec, this.#context.host.ctx.cwd);
		this.#snapshot = snapshot;
		const files: GitFile[] = [];
		for (const kind of KIND_ORDER) {
			for (const entry of snapshot.entries.filter(item => groupOf(item) === kind)) {
				const letter = entry.index !== " " && entry.index !== "" ? entry.index : entry.worktree;
				files.push({ path: entry.path, kind, letter });
			}
		}
		this.#list.set(files);
		this.#loading = false;
		this.#context.refresh();
	}
}
