/** Jobs page: background jobs owned by this session. */
import { Key, matchesKey } from "@oh-my-pi/pi-tui";
import { rightAligned, sectionHeader } from "../../ui/chrome";
import { ListView } from "../list";
import type { EditorKey, EditorTab, EditorTabContext } from "../tab";

interface JobRow {
	id: string;
	type: string;
	status: string;
	label: string;
	duration: string;
}

const KEYS: readonly EditorKey[] = [
	{ key: "↑ ↓", short: "↑↓ move", description: "move in the list" },
	{ key: "r", short: "r reload", description: "reload the jobs" },
];

function duration(start: number, end: number | undefined, now: number): string {
	const seconds = Math.max(0, Math.round(((end ?? now) - start) / 1000));
	if (seconds < 60) return `${seconds}s`;
	const minutes = Math.floor(seconds / 60);
	if (minutes < 60) return `${minutes}m${seconds % 60}s`;
	return `${Math.floor(minutes / 60)}h${minutes % 60}m`;
}

export class JobsTab implements EditorTab {
	readonly id = "jobs";
	readonly label = "Jobs";
	readonly #context: EditorTabContext;
	readonly #list = new ListView<JobRow>();
	#running = 0;
	#message: string | undefined;

	constructor(context: EditorTabContext) {
		this.#context = context;
	}

	activate(): void {
		this.#refresh();
	}

	keys(): readonly EditorKey[] {
		return KEYS;
	}

	render(width: number, height: number): readonly string[] {
		const theme = this.#context.theme;
		const rows: string[] = [];
		rows.push(sectionHeader(theme, `${this.#running} running · ${this.#list.items.length} total`, width));
		rows.push("");
		if (this.#message) rows.push(theme.fg("error", this.#message));
		if (this.#list.items.length === 0) {
			rows.push(theme.fg("muted", "  (no background jobs)"));
			return rows;
		}
		const visible = Math.max(1, height - rows.length);
		const { rows: shown, offset } = this.#list.window(visible);
		shown.forEach((row, position) => {
			const selected = this.#list.isSelected(offset, position);
			const cursor = selected ? theme.fg("accent", theme.symbol("nav.cursor")) : " ";
			const color =
				row.status === "running"
					? "warning"
					: row.status === "completed"
						? "success"
						: row.status === "failed"
							? "error"
							: "muted";
			const status = theme.fg(color, row.status.padEnd(9));
			const label = theme.fg("text", row.label);
			rows.push(`${cursor} ${rightAligned(label, theme.fg("muted", row.duration), Math.max(8, width - 12))} ${status}`);
		});
		return rows;
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
		if (data === "r") {
			this.#refresh();
			return true;
		}
		return false;
	}

	#refresh(): void {
		const snapshot = this.#context.host.ctx.getAsyncJobSnapshot();
		if (!snapshot) {
			this.#list.reset([]);
			this.#running = 0;
			this.#message = "Background jobs are unavailable in this session.";
			this.#context.refresh();
			return;
		}
		const now = Date.now();
		const toRow = (job: {
			id: string;
			type: string;
			status: string;
			label?: string;
			startTime: number;
			endTime?: number;
		}): JobRow => ({
			id: job.id,
			type: job.type,
			status: job.status,
			label: job.label ?? job.type,
			duration: duration(job.startTime, job.endTime, now),
		});
		this.#list.set([...snapshot.running, ...snapshot.recent].map(toRow));
		this.#running = snapshot.running.length;
		this.#message = undefined;
		this.#context.refresh();
	}
}
