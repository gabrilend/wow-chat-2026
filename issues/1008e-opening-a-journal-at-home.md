# 1008e - Opening a Journal at Home

## Status
- Created: 2026-10-26
- Parent: Issue 1008 (journals-of-what-each-player-saw)
- Phase: 10
- **Blocked by:** 1008a
- **Blocks:** 1008f

## Overview

The owner, 2026-10-26: "we don't have to key it to open. Only they do."

Two openers, one format:

- **A page on the owner's website** that opens journal files inside the
  player's own browser. The player drops their files on it and types
  their password; the page remakes the key and shows the text. Nothing
  is sent anywhere: the page is plain HTML and JavaScript using
  libsodium.js, and works saved to disk and opened with the network off.
  This is the opener for players: no install.
- **`scripts/open-journal`**, the same in LuaJIT, for the owner and for
  tests.

## Current Behavior

`scripts/open-journal` is built: `scripts/open-journal FILE...` asks for
the password without echoing it (or reads it from standard input when
not a terminal) and prints each file's lines as
`time  kind  sender: text`, or says which file refused and why (wrong
password, changed, cut short). It uses `scripts/lib/journal-seal.lua`.

The browser page is not built.

## Intended Behavior

- Both openers print a cut-short file's lines up to where it stops, then
  say it was cut short (a server crash), and refuse a changed file
  outright.
- Both accept several passwords (old journals are locked to old
  passwords, 1008 question 2).
- The page shows the lines as a chat window would, with the kinds in
  their game colours, and can save them as a plain text file.

## Suggested Implementation Steps

1. ~~`scripts/open-journal`~~ (built).
2. The page, `website/journal.html` (where the website's files live:
   1008f question 1), libsodium.js from cdnjs.
3. Test: a journal written by `scripts/lib/journal-seal.lua` opens in
   the page (run headless in a browser by the test).

## Related
- `issues/1008a-a-lock-made-from-the-password.md`
- `issues/1008f-how-to-connect-and-read-your-journal.md`
