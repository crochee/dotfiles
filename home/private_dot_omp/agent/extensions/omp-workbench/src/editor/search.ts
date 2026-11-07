/**
 * The project file index behind the quick open.
 *
 * ripgrep does the listing when it is available — it is fast and it already
 * knows the project's ignore rules. Otherwise a bounded walk takes over.
 */
import type { Dirent } from "node:fs";
import { readdir } from "node:fs/promises";
import path from "node:path";
import type { ExecRunner } from "./tab";

export interface SearchMatch {
	/** Path relative to the project root, with `/` separators. */
	relPath: string;
	/** Absolute path. */
	path: string;
}

export interface SearchOptions {
	/** Include dotfiles and dot-directories. */
	showHidden: boolean;
	/** Stop after this many matches. */
	limit?: number;
	/** Give up after this many entries were read. */
	maxEntries?: number;
}

/** Directories that stay out of the index until they are asked for. */
const IGNORED_DIRECTORIES = new Set([
	".git",
	"node_modules",
	"target",
	"dist",
	"build",
	".venv",
	"venv",
	"__pycache__",
	".cache",
	".mypy_cache",
	".pytest_cache",
	".ruff_cache",
	".next",
	".turbo",
	"vendor",
	"coverage",
]);

/** Read one directory, sorted: directories first, then files. */
async function readDirectory(dir: string, options: SearchOptions): Promise<Dirent[]> {
	let items: Dirent[];
	try {
		items = await readdir(dir, { withFileTypes: true });
	} catch {
		return [];
	}
	return items
		.filter(item => {
			if (options.showHidden) return true;
			if (item.name.startsWith(".")) return false;
			return !(item.isDirectory() && IGNORED_DIRECTORIES.has(item.name));
		})
		.sort((a, b) => {
			if (a.isDirectory() !== b.isDirectory()) return a.isDirectory() ? -1 : 1;
			return a.name.localeCompare(b.name, undefined, { sensitivity: "base" });
		});
}

export interface SearchResult {
	matches: SearchMatch[];
	/** How many files the project holds. */
	scanned: number;
	/** True when the result was cut short. */
	truncated: boolean;
}

/**
 * Collect the files whose path contains `query`.
 */
export async function searchFiles(
	root: string,
	query: string,
	options: SearchOptions,
	exec?: ExecRunner,
): Promise<SearchResult> {
	if (exec) {
		const viaRipgrep = await searchWithRipgrep(root, query, options, exec);
		if (viaRipgrep) return viaRipgrep;
	}
	return walkProject(root, query, options);
}

/** List the project with ripgrep; undefined when ripgrep is not usable. */
async function searchWithRipgrep(
	root: string,
	query: string,
	options: SearchOptions,
	exec: ExecRunner,
): Promise<SearchResult | undefined> {
	const args = ["--files", "--no-messages"];
	if (options.showHidden) args.push("--hidden", "--glob", "!.git/");
	let stdout: string;
	try {
		const result = await exec("rg", args, { cwd: root, timeout: 15000 });
		if (result.code !== 0 && result.code !== 1) return undefined;
		stdout = result.stdout;
	} catch {
		return undefined;
	}
	const limit = options.limit ?? 200;
	const needle = query.trim().toLowerCase();
	// ripgrep lists in filesystem order; the quick open is easier to scan when
	// the paths are sorted.
	const files = stdout
		.split("\n")
		.filter(line => line.length > 0)
		.sort((left, right) => left.localeCompare(right, undefined, { sensitivity: "base" }));
	const matches: SearchMatch[] = [];
	for (const relPath of files) {
		if (needle.length > 0 && !relPath.toLowerCase().includes(needle)) continue;
		matches.push({ relPath, path: path.join(root, relPath) });
		if (matches.length >= limit) break;
	}
	return { matches, scanned: files.length, truncated: matches.length >= limit };
}

/**
 * Walk the project and collect files whose path contains `query`.
 */
async function walkProject(
	root: string,
	query: string,
	options: SearchOptions,
): Promise<SearchResult> {
	const needle = query.trim().toLowerCase();
	const limit = options.limit ?? 200;
	const maxEntries = options.maxEntries ?? 20000;
	const matches: SearchMatch[] = [];
	let scanned = 0;
	let truncated = false;

	const walk = async (dir: string): Promise<void> => {
		if (scanned >= maxEntries) {
			truncated = true;
			return;
		}
		for (const item of await readDirectory(dir, options)) {
			if (scanned >= maxEntries) {
				truncated = true;
				return;
			}
			scanned++;
			const full = path.join(dir, item.name);
			if (item.isDirectory()) {
				await walk(full);
				continue;
			}
			const relPath = path.relative(root, full);
			if (needle.length === 0 || relPath.toLowerCase().includes(needle)) {
				matches.push({ relPath, path: full });
				if (matches.length >= limit) {
					truncated = true;
					return;
				}
			}
		}
	};

	await walk(root);
	return { matches, scanned, truncated };
}
