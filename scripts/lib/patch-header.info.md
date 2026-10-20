# lib/patch-header.lua

Reads the header and footer every patch and quick test carries (issue
189a): its id, profiles, priority, kind and a line about it at the top;
the id and the file's line count at the bottom. Returns its table:
`local Header = dofile(".../patch-header.lua")`. The shape is written out
at the top of the source and in `issues/189a-the-header-and-its-reader.md`.

| Function | Takes | Gives |
|---|---|---|
| `Header.parse(text)` | a file's text | a result (below) |
| `Header.read(path)` | a file's path | `Header.parse` of it, with `path`; a file that can't be read is an error |
| `Header.fix_lines(path)` | a file's path | `true` when it rewrote the footer's `lines:` count (the only fault); `false` when nothing needed mending; `false` and the other faults (list of text) when anything else is wrong, leaving the file as it was |

A result is a table:

- `state` (text): `"whole"` (a patch), `"broken"` (opens like one, something
  wrong) or `"absent"` (no header: a helper or a note)
- `fields` (table of text by name): `id`, `profiles`, `priority`, `kind`,
  `about`, and when given `carries`, `quick-test`
- `problems` (list of text): every fault, in plain words, for a broken one
- `marker` (text): `"#"` or `"--"`, the comment marker the header uses
- `lines` (integer): the file's line count; `counted` (integer): the
  footer's
- `header_first`, `header_len`, `footer_len` (integers): where the header
  starts (1, or 2 after a `#!` line) and the two stated lengths

`Header.FIELDS` (table: name to `true` required, `false` optional) and
`Header.KINDS` (table of the five kinds) say what is allowed; any other
field name is a fault.

Used by `scripts/check-patch-headers`; tested by `scripts/test-patch-headers`.
