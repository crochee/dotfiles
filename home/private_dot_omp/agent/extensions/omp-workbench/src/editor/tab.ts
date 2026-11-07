/** Shared contract for the pages of the editor surface. */
import type { ExecResult } from "@oh-my-pi/pi-coding-agent";
import type { SessionHost } from "../sessions/host";
import type { Theme, TUI } from "@oh-my-pi/pi-tui";

/** Runs a command; `cwd` defaults to the session's working directory. */
export type ExecRunner = (
	command: string,
	args: string[],
	options?: { cwd?: string; timeout?: number },
) => Promise<ExecResult>;

/** What the session is doing right now; the header shows it. */
export type SessionState = "working" | "idle";

export interface EditorTabContext {
	host: SessionHost;
	theme: Theme;
	tui: TUI;
	exec: ExecRunner;
	/** Ask the surface to repaint. */
	refresh(): void;
	/** Report a short message in the surface's status line. */
	notify(message: string): void;
	/** Close the surface (a page that switches sessions needs it). */
	close(): void;
	/** The session's live state, for the header. */
	sessionState(): SessionState;
}

/** A key the page binds, with the help text that goes with it. */
export interface EditorKey {
	/** The key or key sequence, e.g. "enter / t". */
	key: string;
	/** What it does, e.g. "open the file tree in nvim". */
	description: string;
	/** The short form for the keybar; defaults to the key. */
	short?: string;
}

export interface EditorTab {
	id: string;
	label: string;
	/** Render the page body; `height` is the number of rows available. */
	render(width: number, height: number): readonly string[];
	/** Handle a key press; return true when the page consumed it. */
	handleInput?(data: string): boolean;
	/** Called when the page becomes the active tab. */
	activate?(): void;
	/**
	 * True while the page owns every printable key, such as a text prompt.
	 * The surface then stops claiming digits and other shortcuts.
	 */
	capturesKeys?(): boolean;
	/**
	 * The keys this page binds. They drive both the keybar and the help
	 * screen, so a page describes its keys in exactly one place.
	 */
	keys?(): readonly EditorKey[];
}

/** Definition other plugins hand to the surface to contribute a page. */
export interface EditorTabDefinition {
	id: string;
	label: string;
	create(context: EditorTabContext): EditorTab;
}
