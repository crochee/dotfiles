/**
 * The scrolling list the pages share.
 *
 * Every page that shows rows needs the same three things: a cursor, a
 * window that keeps the cursor in sight, and a mark for the selected row.
 * Keeping that in one place keeps the pages honest about their bounds — the
 * cursor can never point past the rows it belongs to.
 */
export class ListView<T> {
	#items: readonly T[] = [];
	#index = 0;

	/** The rows in the list. */
	get items(): readonly T[] {
		return this.#items;
	}

	/** The cursor's position in the list. */
	get index(): number {
		return this.#index;
	}

	/** The row under the cursor. */
	get selected(): T | undefined {
		return this.#items[this.#index];
	}

	/** Replace the rows; the cursor stays where it can. */
	set(items: readonly T[]): void {
		this.#items = items;
		this.#index = Math.min(this.#index, Math.max(0, items.length - 1));
	}

	/** Replace the rows and put the cursor back at the top. */
	reset(items: readonly T[]): void {
		this.#items = items;
		this.#index = 0;
	}

	/** Move the cursor, clamped to the list. */
	move(delta: number): void {
		const last = Math.max(0, this.#items.length - 1);
		this.#index = Math.min(last, Math.max(0, this.#index + delta));
	}

	/**
	 * The rows to draw in a body of `height` rows, with the cursor in sight.
	 * The offset is where the window starts in the list.
	 */
	window(height: number): { rows: readonly T[]; offset: number } {
		const count = Math.max(1, height);
		const last = Math.max(0, this.#items.length - count);
		const offset = Math.max(0, Math.min(this.#index - Math.floor(count / 2), last));
		return { rows: this.#items.slice(offset, offset + count), offset };
	}

	/** True when the row at `offset + position` is the one under the cursor. */
	isSelected(offset: number, position: number): boolean {
		return offset + position === this.#index;
	}
}
