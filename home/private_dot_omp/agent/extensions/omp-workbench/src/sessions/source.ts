/**
 * Session discovery for the workbench and the sessions page.
 *
 * Two scopes: the current project's bucket and every project on the machine.
 * The listing calls omp's own session scanner, so titles, lifecycle status,
 * and turn counts match what the built-in resume picker shows.
 */
import {
	FileSessionStorage,
	listAllSessions,
	listSessions,
	type SessionInfo,
	type SessionStatus,
} from "@oh-my-pi/pi-coding-agent";
import { firstLine } from "../ui/chrome";

export type SessionScope = "project" | "all";

export interface SessionRow {
	path: string;
	id: string;
	title: string;
	cwd: string;
	created: number;
	modified: number;
	size: number;
	turns: number;
	status: SessionStatus | undefined;
	/** The session continues another one (fork). */
	derived: boolean;
	/** This row is the session the terminal is currently running. */
	current: boolean;
}

/** Title for a session row: its stored title, else the first user message. */
function sessionTitle(info: SessionInfo): string {
	const title = info.title?.trim();
	if (title) return title;
	const first = info.firstMessage?.trim();
	if (first && first !== "(no messages)") return firstLine(first, 120);
	return "Untitled";
}

/** Sessions with no assistant turn, no title, and no first message carry nothing to show. */
function isEmpty(info: SessionInfo): boolean {
	if (info.status !== undefined && info.status !== "pending" && info.status !== "unknown") return false;
	if ((info.assistantTurns ?? 1) > 0) return false;
	if (info.title?.trim()) return false;
	const first = info.firstMessage?.trim();
	if (first && first !== "(no messages)") return false;
	return true;
}

function toRow(info: SessionInfo, currentPath: string | undefined): SessionRow {
	return {
		path: info.path,
		id: info.id,
		title: sessionTitle(info),
		cwd: info.cwd,
		created: info.created?.getTime() ?? 0,
		modified: info.modified?.getTime() ?? 0,
		size: info.size ?? 0,
		turns: info.assistantTurns ?? 0,
		status: info.status,
		derived: Boolean(info.parentSessionPath),
		current: currentPath !== undefined && info.path === currentPath,
	};
}

/**
 * Sessions of one project bucket, or of every project when `scope` is `all`.
 * The current session is always listed first inside its scope.
 */
export async function loadSessions(options: {
	scope: SessionScope;
	sessionDir: string;
	currentPath?: string;
}): Promise<SessionRow[]> {
	const storage = new FileSessionStorage();
	const listed =
		options.scope === "all" ? await listAllSessions(storage) : await listSessions(options.sessionDir, storage);
	const rows = listed
		.filter(info => !isEmpty(info) || info.path === options.currentPath)
		.map(info => toRow(info, options.currentPath))
		.sort((left, right) => right.modified - left.modified);
	const current = rows.findIndex(row => row.current);
	if (current > 0) {
		const [row] = rows.splice(current, 1);
		rows.unshift(row);
	}
	const live = rows.find(row => row.current);
	if (live && live.title === "Untitled") live.title = "New session";
	return rows;
}
