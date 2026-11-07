/**
 * Turn-structured outline of a session file.
 *
 * The workbench shows what a session actually did: every user prompt, the
 * assistant's reply headline, and the tools it called. The file is a JSONL
 * log, so the outline is a linear scan over its entries; unknown entry kinds
 * are skipped instead of guessed at.
 */
import { readFile } from "node:fs/promises";

export type OutlineKind = "user" | "assistant" | "tool" | "note";

export interface OutlineItem {
	kind: OutlineKind;
	text: string;
}

export interface SessionOutline {
	items: OutlineItem[];
	/** The outline was cut short because the session had more entries than the budget. */
	truncated: boolean;
}

interface TextBlock {
	type?: string;
	text?: string;
	name?: string;
}

interface MessageLike {
	role?: string;
	content?: unknown;
}

function blockText(block: TextBlock): string {
	if (block.type === "text" && typeof block.text === "string") return block.text;
	if (block.type === "toolCall" && typeof block.name === "string") return block.name;
	return "";
}

function collectMessage(message: MessageLike, items: OutlineItem[]): void {
	const role = message.role;
	const content = message.content;
	const blocks: TextBlock[] = Array.isArray(content) ? (content as TextBlock[]) : [];
	if (role === "user") {
		const text = blocks.map(blockText).filter(Boolean).join(" ").trim();
		if (text) items.push({ kind: "user", text });
		return;
	}
	if (role !== "assistant") return;
	for (const block of blocks) {
		if (block.type === "text" && typeof block.text === "string" && block.text.trim()) {
			items.push({ kind: "assistant", text: block.text.trim() });
		} else if (block.type === "toolCall" && typeof block.name === "string") {
			items.push({ kind: "tool", text: block.name });
		}
	}
}

/** Read a session file and reduce it to a bounded outline. */
export async function readSessionOutline(path: string, maxItems = 120): Promise<SessionOutline> {
	const items: OutlineItem[] = [];
	let truncated = false;
	let raw: string;
	try {
		raw = await readFile(path, "utf8");
	} catch {
		return { items, truncated };
	}
	for (const line of raw.split("\n")) {
		if (line.length === 0) continue;
		let entry: Record<string, unknown>;
		try {
			entry = JSON.parse(line) as Record<string, unknown>;
		} catch {
			continue;
		}
		if (entry.type === "message") {
			collectMessage(entry.message as MessageLike, items);
		} else if (entry.type === "compaction") {
			items.push({ kind: "note", text: "context compacted" });
		} else if (entry.type === "branch_summary") {
			items.push({ kind: "note", text: "branch summary" });
		} else if (entry.type === "label") {
			const label = entry.label;
			if (typeof label === "string" && label) items.push({ kind: "note", text: `label: ${label}` });
		}
		if (items.length >= maxItems) {
			truncated = true;
			break;
		}
	}
	return { items, truncated };
}
