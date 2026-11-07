/** Type-to-filter for the pages: printable keys narrow the list. */

export interface FilterResult {
	query: string;
	/** The page handled the key (the filter changed, or the query was cleared). */
	consumed: boolean;
}

/**
 * Fold a key into a filter query. Backspace removes a character while the
 * query is non-empty and is left to the page otherwise; Escape clears the
 * query and is only consumed when there was one.
 */
export function applyFilterKey(query: string, data: string): FilterResult {
	if (data.length === 1 && data >= " " && data <= "~") {
		return { query: query + data, consumed: true };
	}
	if (data === "\x7f" || data === "\b") {
		if (query.length === 0) return { query, consumed: false };
		return { query: query.slice(0, -1), consumed: true };
	}
	if (data === "\x1b") {
		return { query: "", consumed: query.length > 0 };
	}
	return { query, consumed: false };
}

/** Case-insensitive substring match against a row's searchable text. */
export function matchesFilter(query: string, text: string): boolean {
	if (query.length === 0) return true;
	return text.toLowerCase().includes(query.toLowerCase());
}
