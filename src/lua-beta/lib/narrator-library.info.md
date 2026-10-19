# lib/narrator-library.lua

Which sentence each narrator says next (issue 909, for the narrators of
issue 910). Returns its table (`local Library = dofile(...)`); sets no global. Reads the shelf
(`data/gutenberg-books.lua`) and the built books (`data/texts/`) beside
this tree, lazily. Tested by `scripts/test-gutenberg-library`.

Each narrator is keyed by an instance id: the narrator bot's character number in
game (any value usable as a table key). State lives in memory only and is
forgotten on `clearInstance`; nothing goes to the database.

| Function | Takes | Gives |
|---|---|---|
| `Library.start(id)` | id | nothing; a random built book, place 0, mode STORY. Starting one twice is an error |
| `Library.getNextSentence(id)` | id | the next sentence (text); past the book's last, a different random book from its first |
| `Library.getCurrentBook(id)` | id | `{ id, slug, title, author, genre, sentences }`: the shelf entry's fields (id the Gutenberg number, an integer) and the book's sentence count (integer) |
| `Library.getPosition(id)` / `Library.setPosition(id, n)` | n: integer, 0 to the book's count | how many sentences of the book it has said / sets it; outside the range is an error |
| `Library.setBook(id, gutenberg_id)` | gutenberg_id: integer | nothing; that book from place 0. A book not built is an error |
| `Library.getMode(id)` / `Library.setMode(id, mode)` | mode: `Library.STORY` or `Library.RUMORS` | the mode / sets it; the place in the book is unchanged. Anything else is an error |
| `Library.clearInstance(id)` | id | nothing; forgets it. One never started is an error |
| `Library.availableBooks()` | nothing | built (integer), on the shelf (integer) |

Every function but `start` and `availableBooks` errors on an id that was
never started. No book built at all is an error naming the scraper.

Settable for tests: `Library.DATA_DIR` (text, the folder holding
`gutenberg-books.lua` and `texts/`), `Library.random` (function n -> 1..n).
