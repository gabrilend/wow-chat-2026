# 001-connection-page-wide-basic-open

## What made it
- Tool: `scripts/write-connection-page --preview --screenshot basic`
- Commit: 35ec16d (the working tree may hold uncommitted changes)
- Window: 900 x 2200, headless Firefox
- Sources fingerprint (BLAKE2b of the script and docs/profiles/*.md): d3e5e4b80a875aad2289967d4ef3db344eb2c253a1cf126bab0b937fcc4c9568dbd2699aaf21e4f8c24aa3519a56a5691bf7f57f27ad5e621c7e4bd6ac990559

## What changed since the previous picture
Compare the fingerprint above with the previous picture's.

## What it shows
The public connection page, 900 px wide, in preview (an amber banner: the login machine's name is not chosen). Top to bottom: the title "Everland Ghostsong" in thin blue type over a sky gradient with glass bubbles; "The realms", a glass panel holding six rounded rows, each a blue gel orb with the realm's number, its name and its one-line summary, and a chevron; Basic (5) is open, listing sixteen points under "What is here" (each opens to its detail; "Slower movement (80%), heavier fall damage (10×)." has none, so it shows flat) and three under "Left out on purpose", the last two now whole sentences; the panel scrolls inside itself, so Basic's "Connect to Basic" button is cut at the panel's edge; below it, "How to connect": three steps and the realmlist line showing "(name not chosen yet)".

## The story so far
The owner asked (2026-10-26) for the public game to move to rented Linode machines, every realm at once, with a public page telling players how to connect; that page is to list every realm as a scrollable, expandable listing in the Frutiger Aero style of the hall-of-president-spirits project, each realm pointing to the same connection details. These are the first pictures of that page, generated from the realms' own documentation pages by scripts/write-connection-page. The first draft split points without a bold opening at a colon ("Northrend:" alone, its explanation hidden); this draft splits only at a full stop. One internal reference remains, in beta's page (its setup step's name), reported by the tool as a warning.
