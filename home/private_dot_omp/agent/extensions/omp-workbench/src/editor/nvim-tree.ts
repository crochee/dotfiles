/**
 * nvim-tree integration.
 *
 * The file tree is nvim-tree's, not ours: the page checks that the editor
 * can load the plugin and then hands the terminal to nvim with the tree
 * open at the project root.
 */
import type { TUI } from "@oh-my-pi/pi-tui";
import { launchProgram, type LaunchResult } from "./launch";
import type { ExecRunner } from "./tab";

export interface NvimTreeStatus {
	/** nvim itself is on the PATH. */
	nvim: boolean;
	/** That nvim can load nvim-tree. */
	plugin: boolean;
	/** The nvim version line, when nvim answered. */
	version?: string;
	/** A line for the page to show. */
	detail: string;
}

const MARKER = "NVIM_TREE_OK";

/** The Lua that reports whether nvim-tree can be loaded. */
const DETECT_LUA = `lua io.write(pcall(require, 'nvim-tree.api') and '${MARKER}' or 'NVIM_TREE_MISSING')`;

/** Ask nvim whether it can load nvim-tree, and which version it is. */
export async function detectNvimTree(exec: ExecRunner): Promise<NvimTreeStatus> {
	let stdout = "";
	try {
		const result = await exec("nvim", ["--headless", "-c", DETECT_LUA, "-c", "qa!"], { timeout: 15000 });
		stdout = result.stdout;
	} catch {
		return { nvim: false, plugin: false, detail: "nvim was not found on the PATH" };
	}
	if (!stdout.includes(MARKER)) {
		return {
			nvim: true,
			plugin: false,
			detail: "nvim-tree is not installed for this nvim",
		};
	}
	let version: string | undefined;
	try {
		const result = await exec("nvim", ["--version"], { timeout: 10000 });
		version = result.stdout.split("\n")[0]?.trim() || undefined;
	} catch {
		version = undefined;
	}
	return {
		nvim: true,
		plugin: true,
		version,
		detail: version ? `nvim-tree ready · ${version}` : "nvim-tree ready",
	};
}

/** The Lua that opens nvim-tree at the project root. */
function openLua(root: string): string {
	const escaped = root.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
	return `lua require('nvim-tree.api').tree.open({ path = '${escaped}' })`;
}

/** Hand the terminal to nvim with nvim-tree open at `root`. */
export async function launchNvimTree(tui: TUI, root: string): Promise<LaunchResult> {
	return launchProgram(tui, "nvim", ["-c", openLua(root)]);
}
