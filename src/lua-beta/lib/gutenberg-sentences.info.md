# lib/gutenberg-sentences.lua

Turns a Project Gutenberg plain-text book into the story's sentences
(issue 909). Plain text work, no server calls. Used by
`scripts/gutenberg-scraper`; tested by `scripts/test-gutenberg-library`.

| Function | Takes | Gives |
|---|---|---|
| `Sentences.strip_boilerplate(text)` | text: a whole Gutenberg file | the text between the `*** START OF` and `*** END OF` lines; either missing is an error |
| `Sentences.title_of(text)` | text | the header's `Title:` line, or nil |
| `Sentences.plain_punctuation(text)` | text | curly quotes, dashes, the ellipsis character and no-break spaces as plain ASCII |
| `Sentences.paragraphs(story)` | story: the stripped text | list of paragraphs (text), each on one line; picture markers, footnote markers, `{marginal notes}` and `_italic_` marks removed; headings, titles, bylines and tables of contents left out |
| `Sentences.split(p)` | p: one paragraph | list of sentences (text), cut at `. ! ?` before a capital or digit; never at commas, abbreviations (`Sentences.ABBREVIATIONS`), initials (except "I"), or spaced dots |
| `Sentences.from_gutenberg(text, opts)` | text; opts: a shelf entry or nil (`starts`, `ends`, `verse_line_numbers`, see below) | the whole book's sentences in order; `starts`/`ends` words not found are an error |
| `Sentences.speakable_parts(s, max)` | s: a sentence; max: bytes per chat line (255) | list of parts, each at most `max`, cut at the last `; ` then `, ` then space |

`opts` fields, all optional:
- `starts` (text): sentences before the first one beginning with it are left out.
- `ends` (text): the sentence beginning with it and everything after are left out.
- `verse_line_numbers` (true): numbers that are multiples of 5 between words, or opening a paragraph, are removed (Beowulf's translator numbers every fifth line).

Always left out: paragraphs opening with a bracketed footnote number
(`[46]`, `[454b]`), bare `CHAPTER IV.` lines (a heading glued to a chapter
summary keeps the summary), and the sentence "End of Project Gutenberg...".
