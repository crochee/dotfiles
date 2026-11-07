/**
 * Session capabilities the workbench needs.
 *
 * Command contexts expose session switching; shortcut handlers only get the
 * plain extension context, so switching is optional and the UI says so when
 * it is missing.
 */
import { rm, unlink } from "node:fs/promises";
import type { ExtensionContext } from "@oh-my-pi/pi-coding-agent";

export interface SessionHost {
	ctx: ExtensionContext;
	/** Switch the terminal to another session file. */
	switchSession?(path: string): Promise<{ cancelled: boolean }>;
	/** Delete a session file and its artifact directory. */
	dropSession?(path: string): Promise<void>;
}

/** Delete a session journal and the artifact directory that sits beside it. */
export async function deleteSessionFile(path: string): Promise<void> {
	try {
		await unlink(path);
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
	}
	if (!path.endsWith(".jsonl")) return;
	await rm(path.slice(0, -".jsonl".length), { recursive: true, force: true });
}
