/** Git state for the Git page: branch, working tree, recent commits. */
import type { ExecRunner } from "./tab";

export interface GitStatusEntry {
	/** Index (staged) status letter. */
	index: string;
	/** Working-tree status letter. */
	worktree: string;
	path: string;
}

export interface GitCommit {
	hash: string;
	subject: string;
}

export interface GitSnapshot {
	isRepo: boolean;
	/** Absolute path of the repository root; "" when there is no repository. */
	root: string;
	branch: string;
	upstream: string;
	ahead: number;
	behind: number;
	entries: GitStatusEntry[];
	commits: GitCommit[];
	error: string | undefined;
}

const EMPTY: GitSnapshot = {
	isRepo: false,
	root: "",
	branch: "",
	upstream: "",
	ahead: 0,
	behind: 0,
	entries: [],
	commits: [],
	error: undefined,
};

function parseStatus(output: string): Omit<GitSnapshot, "commits" | "root"> {
	let branch = "";
	let upstream = "";
	let ahead = 0;
	let behind = 0;
	const entries: GitStatusEntry[] = [];
	for (const line of output.split("\n")) {
		if (line.length === 0) continue;
		if (line.startsWith("## ")) {
			const header = line.slice(3);
			const [name, rest = ""] = header.split(" ");
			branch = name ?? "";
			const tracking = rest.match(/\[(.+)\]/);
			if (tracking) {
				const parts = tracking[1].split(",").map(part => part.trim());
				upstream = parts[0]?.startsWith("origin/") ? parts[0] : (parts[0] ?? "");
				const aheadMatch = parts.find(part => part.startsWith("ahead "));
				const behindMatch = parts.find(part => part.startsWith("behind "));
				ahead = aheadMatch ? Number.parseInt(aheadMatch.slice(6), 10) || 0 : 0;
				behind = behindMatch ? Number.parseInt(behindMatch.slice(7), 10) || 0 : 0;
			}
			continue;
		}
		const index = line[0] ?? " ";
		const worktree = line[1] ?? " ";
		const path = line.slice(3).trim();
		if (path.length > 0) entries.push({ index, worktree, path });
	}
	return { isRepo: true, branch, upstream, ahead, behind, entries, error: undefined };
}

function parseLog(output: string): GitCommit[] {
	const commits: GitCommit[] = [];
	for (const line of output.split("\n")) {
		if (line.trim().length === 0) continue;
		const match = line.match(/^([0-9a-f]{7,40})\s+(.*)$/);
		if (match) commits.push({ hash: match[1], subject: match[2] });
	}
	return commits;
}

/** Read branch, working tree, and recent commits in one pass. */
export async function readGitSnapshot(exec: ExecRunner, cwd: string): Promise<GitSnapshot> {
	const status = await exec("git", ["status", "--porcelain=v1", "-b", "--untracked-files=normal"], { cwd });
	if (status.code !== 0) {
		return { ...EMPTY, error: status.stderr.trim() || "not a git repository" };
	}
	const parsed = parseStatus(status.stdout);
	const log = await exec("git", ["log", "--oneline", "-n", "20", "--no-color"], { cwd });
	const toplevel = await exec("git", ["rev-parse", "--show-toplevel"], { cwd });
	return {
		...parsed,
		root: toplevel.code === 0 ? toplevel.stdout.trim() : "",
		commits: log.code === 0 ? parseLog(log.stdout) : [],
	};
}
