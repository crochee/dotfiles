/**
 * Hand a file to the user's editor.
 *
 * The TUI stops first so the editor owns the terminal, and starts again
 * afterwards. The editor is `$VISUAL`, then `$EDITOR`, then `nvim`.
 */
import { spawn } from "node:child_process";
import { accessSync, constants } from "node:fs";
import path from "node:path";
import type { TUI } from "@oh-my-pi/pi-tui";

/** Values that stand for "no editor" and must not be launched. */
const PLACEHOLDERS = new Set(["true", "false", ":", " "]);

/** True when the program of a command line can be found on the PATH. */
function programExists(command: string): boolean {
	const program = command.split(/\s+/)[0] ?? command;
	if (program.includes("/")) {
		try {
			accessSync(program, constants.X_OK);
			return true;
		} catch {
			return false;
		}
	}
	const searchPath = process.env.PATH ?? "";
	for (const dir of searchPath.split(":")) {
		if (!dir) continue;
		try {
			accessSync(path.join(dir, program), constants.X_OK);
			return true;
		} catch {
			// Keep looking.
		}
	}
	return false;
}

/**
 * The command the surface launches files with: `$VISUAL`, then `$EDITOR`,
 * then nvim. Placeholder values such as `EDITOR=true` are skipped.
 */
export function editorCommand(): string {
	for (const value of [process.env.VISUAL, process.env.EDITOR]) {
		const command = value?.trim();
		if (!command || PLACEHOLDERS.has(command)) continue;
		if (programExists(command)) return command;
	}
	for (const fallback of ["nvim", "vim", "vi"]) {
		if (programExists(fallback)) return fallback;
	}
	return "nvim";
}

/** The editor's name without its path, for messages. */
export function editorName(command = editorCommand()): string {
	const program = command.split(/\s+/)[0] ?? command;
	return program.split("/").pop() || program;
}

export interface LaunchResult {
	/** The editor's exit code, or -1 when it could not be started. */
	code: number;
	/** Set when the editor could not be started at all. */
	error?: string;
}

/**
 * Run a program with the terminal attached. The TUI is stopped for the
 * duration and restarted afterwards, so the surface comes back.
 */
export async function launchProgram(tui: TUI, program: string, args: readonly string[]): Promise<LaunchResult> {
	tui.stop();
	try {
		const child = spawn(program, [...args], { stdio: "inherit" });
		const code = await new Promise<number>(resolve => {
			child.on("error", () => resolve(-1));
			child.on("exit", exitCode => resolve(exitCode ?? 0));
		});
		return code === -1 ? { code, error: `could not start ${program}` } : { code };
	} catch (error) {
		return { code: -1, error: error instanceof Error ? error.message : String(error) };
	} finally {
		tui.start();
		tui.requestRender(true);
	}
}

/**
 * Open `file` in the editor with the terminal attached. The TUI is stopped
 * for the duration and restarted afterwards, so the surface comes back.
 */
export async function launchEditor(tui: TUI, file: string): Promise<LaunchResult> {
	const command = editorCommand();
	tui.stop();
	try {
		const child = spawn("sh", ["-c", `${command} "$1"`, "sh", file], { stdio: "inherit" });
		const code = await new Promise<number>(resolve => {
			child.on("error", () => resolve(-1));
			child.on("exit", exitCode => resolve(exitCode ?? 0));
		});
		return code === -1 ? { code, error: `could not start ${editorName(command)}` } : { code };
	} catch (error) {
		return { code: -1, error: error instanceof Error ? error.message : String(error) };
	} finally {
		tui.start();
		tui.requestRender(true);
	}
}
