/**
 * Persisted panel state.
 *
 * The project groups the workbench opens and the shape of the file tree
 * survive a restart; the file lives in the XDG state directory so it never
 * mixes with the plugin's own sources.
 */
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";

export interface WorkbenchState {
	/** Project path -> whether its session group is open. */
	groups: Record<string, "open" | "closed">;
	/** The quick open's shape, so it comes back the way it was left. */
	editor?: {
		/** Whether the quick open lists dotfiles. */
		showHidden: boolean;
	};
}

const EMPTY: WorkbenchState = { groups: {} };

function stateDir(): string {
	const base = process.env.XDG_STATE_HOME?.trim() || path.join(homedir(), ".local", "state");
	return path.join(base, "omp-workbench");
}

function stateFile(): string {
	return path.join(stateDir(), "state.json");
}

/** Read the persisted state; a missing or broken file yields the defaults. */
export async function loadState(): Promise<WorkbenchState> {
	try {
		const raw = await readFile(stateFile(), "utf8");
		const parsed = JSON.parse(raw) as Partial<WorkbenchState>;
		const groups: Record<string, "open" | "closed"> = {};
		for (const [key, value] of Object.entries(parsed.groups ?? {})) {
			if (value === "open" || value === "closed") groups[key] = value;
		}
		const editor = parsed.editor ? { showHidden: parsed.editor.showHidden === true } : undefined;
		return { groups, editor };
	} catch {
		return { ...EMPTY, groups: {} };
	}
}

/** Persist the state; failures are ignored (the panel keeps working). */
export async function saveState(state: WorkbenchState): Promise<void> {
	try {
		await mkdir(stateDir(), { recursive: true });
		await writeFile(stateFile(), `${JSON.stringify(state, null, 2)}\n`, "utf8");
	} catch {
		// A read-only state directory must not break the panel.
	}
}
