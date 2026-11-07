/** Human-readable formatting for session metadata. */

/** Lifecycle state of a session, as omp reports it. */
export type SessionState = "complete" | "interrupted" | "aborted" | "error" | "pending" | "unknown";

/** Theme color that reads best for a session state. */
export function statusColor(status: SessionState | undefined): "success" | "warning" | "error" | "accent" | "muted" {
	switch (status) {
		case "complete":
			return "success";
		case "interrupted":
		case "aborted":
			return "warning";
		case "error":
			return "error";
		case "pending":
			return "accent";
		default:
			return "muted";
	}
}

/** "3m ago", "2h ago", "5d ago" — compact relative time for list rows. */
export function timeAgo(timestamp: number, now = Date.now()): string {
	const seconds = Math.max(0, Math.round((now - timestamp) / 1000));
	if (seconds < 45) return `${seconds}s ago`;
	const minutes = Math.round(seconds / 60);
	if (minutes < 60) return `${minutes}m ago`;
	const hours = Math.round(minutes / 60);
	if (hours < 24) return `${hours}h ago`;
	const days = Math.round(hours / 24);
	if (days < 30) return `${days}d ago`;
	const months = Math.round(days / 30);
	if (months < 12) return `${months}mo ago`;
	return `${Math.round(months / 12)}y ago`;
}

/** Local timestamp, "2026-11-07 14:22". */
export function timestamp(date: Date): string {
	const pad = (value: number): string => value.toString().padStart(2, "0");
	return (
		`${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ` +
		`${pad(date.getHours())}:${pad(date.getMinutes())}`
	);
}

/** Byte count as "1.2 KB" / "3.4 MB". */
export function fileSize(bytes: number): string {
	if (!Number.isFinite(bytes) || bytes < 0) return "-";
	if (bytes < 1024) return `${bytes} B`;
	const units = ["KB", "MB", "GB", "TB"];
	let value = bytes / 1024;
	let unit = 0;
	while (value >= 1024 && unit < units.length - 1) {
		value /= 1024;
		unit++;
	}
	return `${value.toFixed(value >= 10 ? 0 : 1)} ${units[unit]}`;
}

/** Last path segment of a POSIX path. */
export function basename(path: string): string {
	const trimmed = path.replace(/\/+$/, "");
	const index = trimmed.lastIndexOf("/");
	return index === -1 ? trimmed : trimmed.slice(index + 1);
}

/** Collapse `$HOME` to `~` for display. */
export function tildify(path: string, home: string): string {
	if (!home || !path.startsWith(home)) return path;
	const rest = path.slice(home.length);
	return rest.startsWith("/") ? `~${rest}` : `~/${rest}`;
}
