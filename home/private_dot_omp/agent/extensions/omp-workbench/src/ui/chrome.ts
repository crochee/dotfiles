/**
 * Panel chrome for the workbench and editor surfaces.
 *
 * Every row is built here so the two surfaces share one geometry: a rounded
 * frame, an optional two-column split, and ANSI-aware padding. Glyphs and
 * colors come from the live theme, so the panel follows the user's preset
 * (including the ASCII preset, which has no box-drawing characters).
 */
import { type Theme, replaceTabs, truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@oh-my-pi/pi-tui";

/** Columns consumed by the frame around a two-column split body. */
const SPLIT_CHROME = 7;

/** Body width of a two-column frame whose left column is `leftWidth` wide. */
export function splitBodyWidth(width: number, leftWidth: number): number {
	return Math.max(0, width - leftWidth - SPLIT_CHROME);
}

/** 0-based column of the divider between the two split columns. */
export function splitDividerCol(leftWidth: number): number {
	return leftWidth + 3;
}

/** Truncate to `width` cells after removing tabs. */
export function fit(text: string, width: number): string {
	if (width <= 0) return "";
	return truncateToWidth(replaceTabs(text), width);
}

/** Right-pad to exactly `width` cells, truncating when the text is wider. */
export function padTo(text: string, width: number): string {
	if (width <= 0) return "";
	const w = visibleWidth(text);
	if (w > width) return truncateToWidth(text, width);
	return text + " ".repeat(width - w);
}

/** First non-blank line of a multi-line string, collapsed to one line. */
export function firstLine(text: string, limit = 400): string {
	for (const raw of text.split("\n")) {
		const line = raw.trim();
		if (line.length > 0) return line.length > limit ? line.slice(0, limit) : line;
	}
	return "";
}

/** Top border with an optional title inset into the rule. */
export function topBorder(theme: Theme, width: number, title: string): string {
	const box = theme.boxRound;
	const inner = Math.max(0, width - 2);
	if (!title) return theme.fg("border", box.topLeft + box.horizontal.repeat(inner) + box.topRight);
	const shown = fit(` ${title} `, Math.max(0, inner - 2));
	const fill = Math.max(0, inner - 1 - visibleWidth(shown));
	return (
		theme.fg("border", box.topLeft + box.horizontal) +
		theme.bold(theme.fg("accent", shown)) +
		theme.fg("border", box.horizontal.repeat(fill) + box.topRight)
	);
}

/** Top border carrying a title and a tee over the split divider. */
export function topBorderSplit(theme: Theme, width: number, title: string, leftWidth: number): string {
	const box = theme.boxRound;
	const dividerCol = splitDividerCol(leftWidth);
	const leftLen = Math.max(0, dividerCol - 1);
	const rightLen = Math.max(0, width - 2 - dividerCol);
	let left: string;
	if (!title) {
		left = theme.fg("border", box.topLeft + box.horizontal.repeat(leftLen));
	} else {
		const shown = fit(` ${title} `, Math.max(0, leftLen - 1));
		const fill = Math.max(0, leftLen - 1 - visibleWidth(shown));
		left =
			theme.fg("border", box.topLeft + box.horizontal) +
			theme.bold(theme.fg("accent", shown)) +
			theme.fg("border", box.horizontal.repeat(fill));
	}
	return left + theme.fg("border", box.teeDown + box.horizontal.repeat(rightLen) + box.topRight);
}

/** Rule that closes the left column with a tee over the divider. */
export function dividerSplit(theme: Theme, width: number, leftWidth: number): string {
	const box = theme.boxRound;
	const dividerCol = splitDividerCol(leftWidth);
	const leftLen = Math.max(0, dividerCol - 1);
	const rightLen = Math.max(0, width - 2 - dividerCol);
	return theme.fg(
		"border",
		box.teeRight + box.horizontal.repeat(leftLen) + box.teeUp + box.horizontal.repeat(rightLen) + box.teeLeft,
	);
}

/** Bottom border. */
export function bottomBorder(theme: Theme, width: number): string {
	const box = theme.boxRound;
	return theme.fg("border", box.bottomLeft + box.horizontal.repeat(Math.max(0, width - 2)) + box.bottomRight);
}

/** One body row of a two-column frame: `│ left │ right │`. */
export function splitRow(
	theme: Theme,
	left: string,
	right: string,
	width: number,
	leftWidth: number,
): string {
	const box = theme.boxRound;
	const bodyWidth = splitBodyWidth(width, leftWidth);
	const bar = theme.fg("border", box.vertical);
	return (
		`${bar} ${leftWidth > 0 ? padTo(left, leftWidth) : ""} ${bar} ` +
		`${bodyWidth > 0 ? padTo(right, bodyWidth) : ""} ${bar}`
	);
}

/** One body row spanning the full frame width. */
export function fullRow(theme: Theme, content: string, width: number): string {
	const box = theme.boxRound;
	const inner = Math.max(0, width - 4);
	return `${theme.fg("border", box.vertical)} ${padTo(content, inner)} ${theme.fg("border", box.vertical)}`;
}

/** Aligned `label  value` rows for a detail pane. */
export function keyValueRows(
	theme: Theme,
	rows: readonly (readonly [string, string])[],
	labelWidth: number,
	valueWidth: number,
): string[] {
	return rows.map(([label, value]) => {
		const l = theme.fg("muted", padTo(label, labelWidth));
		return `${l} ${fit(value, Math.max(0, valueWidth))}`.trimEnd();
	});
}

/** A section label with a trailing rule: `SESSION ─────────────`. */
export function sectionHeader(theme: Theme, label: string, width: number): string {
	const text = theme.bold(theme.fg("accent", label));
	const rule = theme.fg("borderMuted", theme.boxRound.horizontal.repeat(Math.max(0, width - visibleWidth(text) - 1)));
	return `${text} ${rule}`;
}

/** A bold label followed by dim context: `SESSIONS 124 · this project`. */
export function metaHeader(theme: Theme, label: string, meta: string, width: number): string {
	return fit(`${theme.bold(theme.fg("accent", label))} ${theme.fg("muted", meta)}`, width);
}

/** A bracketed pill, e.g. `[current]`, used for session state markers. */
export function badge(theme: Theme, text: string, color: "accent" | "muted" | "warning" | "success" | "error"): string {
	return theme.fg(color, `[${text}]`);
}

/** Lay `right` out flush with the right edge of a `width`-wide row. */
export function rightAligned(left: string, right: string, width: number): string {
	const rightWidth = visibleWidth(right);
	const leftWidth = Math.max(0, width - rightWidth - 1);
	return `${padTo(fit(left, leftWidth), leftWidth)} ${right}`;
}

/**
 * Wrap `text` under a fixed prefix; continuation lines align under the text
 * column instead of under the prefix.
 */
export function wrapIndented(prefix: string, text: string, width: number): string[] {
	const prefixWidth = visibleWidth(prefix);
	const body = Math.max(8, width - prefixWidth);
	const lines = wrapTextWithAnsi(text.replace(/\s+/g, " ").trim(), body);
	const indent = " ".repeat(prefixWidth);
	return lines.map((line, index) => (index === 0 ? `${prefix}${line}` : `${indent}${line}`));
}
