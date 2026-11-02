# Rewrite quality rubric

How a rewrite is judged after the scan. Four of the five criteria are mechanical and are checked by
`tests/rewrite_eval.py`. The fifth is a reading test and belongs to a human.

Score each criterion 0–3:

- **3** — fully met, nothing to change.
- **2** — met with one small gap the reviewer can name.
- **1** — partly met; the gap changes what a reader would believe.
- **0** — not met.

A rewrite passes when every mechanical criterion scores 3 and the reading criterion scores at
least 2.

## 1. The scan is clean (mechanical)

Run the scanner on the delivered file. The final scan must report the pattern numbers the case
expects to be cleared, and nothing else. A hit that survives needs a row in the change log's
*Surviving hits* table with a reason a reviewer can check against the source.

## 2. No number, date or proper noun was lost or invented (mechanical)

Extract the numeric tokens and the identifiers from the input and from the rewrite. The rewrite must
contain every token of the input, and may not contain a token the input did not have. The runner
checks the numbers and the named terms separately; both must hold. A lower score with a lost
figure fails this criterion on its own.

## 3. Every modal qualifier survived (mechanical)

Check `may`, `might`, `must`, `should`, `only`, `up to`, `at least`, `不超过`, `至少` and `仅`. Each
one that was in the input must be in the rewrite, or its removal must have a row in the change log.

## 4. The delivery language is right (mechanical)

A Chinese case must read as Chinese: most sentences end with a full-width mark, and the ratio of
Chinese characters to Latin words is in the range the case sets. An English case must read as
English. A mixed case follows the language of the conversation.

## 5. It reads like a person wrote it (a reader)

Read the rewrite aloud, without looking at the original. Ask what still sounds generated. Count the
tells the scanner cannot see:

- The same sentence opening twice in a row for no reason.
- Every sentence the same length.
- A paragraph that ends by restating itself.
- Words that sound formal but say nothing — 「赋能」「闭环」「底层逻辑」and their English equivalents.
- A sentence that exists to connect two other sentences.
- A rhythm that never breaks: no short sentence after a long one, no aside, no asides at all.

A rewrite that scores well on the scanner and badly here has been laundered, not fixed. Three tells
left in a page of prose is a normal result; ten means the rewrite only patched phrases.
