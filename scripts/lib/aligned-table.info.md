# lib/aligned-table.lua

Markdown tables whose numbers line up by place value: ones digits in one
column, decimal points in one column, in the raw text (CLAUDE.md, Vertical
Alignment). Returns its table: `local Table = dofile(".../aligned-table.lua")`.

| Function | Takes | Gives |
|---|---|---|
| `Table.lines(header, rows)` | header: list of column names (text); rows: list of lists of cells (text or numbers) | list of lines (text): the header, a separator of dashes, one line per row |

A cell is a number when it is digits with an optional sign and decimal
point (`-1`, `0.85`, `180000`); its whole part is padded on the left to the
column's widest and its fraction on the right. Any other cell is text,
padded on the right. Thousands separators make a cell text.

Used by `scripts/compare-wow-chat-1-settings` and `scripts/report-intuition-copy`.
