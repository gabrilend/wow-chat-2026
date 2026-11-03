# 003-connection-page-wide

## What made it
- Tool: `scripts/write-connection-page --preview --screenshot`
- Commit: 35ec16d (the working tree may hold uncommitted changes)
- Window: 900 x 1500, headless Firefox
- Sources fingerprint (BLAKE2b of the script and docs/profiles/*.md): 93914686a24c395758fe20c55ff8f5627feca6a64d4a1f2f133bb9f7b07bd8968d9a62d7a87beee6b102818aca23963af06c424b6d74a1839631677c26b39081

## What changed since the previous picture
Compare the fingerprint above with the previous picture's.

## What it shows
900 px wide, all realms closed. The realm list now ends with the page's own flow (no inner scroll bar); below it "Side by side": a glass table, realms as columns (Release, Beta, Vanilla, Alpha, Basic, cc-test), rows Levels (1-20, 1-20, 20-40, 40-80 wrapped onto two lines, 1-60, 1-80), the empty world with ambushes (Release, Beta), AI playerbots in the world (Release, Beta, Vanilla), no flight paths (Vanilla, Basic), slower movement and heavier falls (Vanilla, Basic), and the start of Death knights, cut by the picture's bottom edge. Ticks are green glossy dots, absences faint dashes; the header "cc-test" wraps.

## The story so far
After pictures 001-002 the owner (2026-10-27) liked the page and asked for two changes: an opened realm should scroll the whole page, not a box inside it, and a comparison table of the major shared features, ending with "and many more features!" ticked for every realm but alpha. Both are in: the realm list no longer has its own scroll, and "Side by side" is a table whose every filled cell quotes the words in that realm's page that prove it (the tool stops if a quote disappears). Next (after these pictures): table cells and headers kept on one line, since "40-80" and "cc-test" wrapped.
