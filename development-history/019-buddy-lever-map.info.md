# 019-buddy-lever-map

## What made it
- scripts/generate-buddy-lever-map (nomic-embed-text:v1.5, 19 segments, seed 638), then scripts/generate-buddy-lever-map-page; photographed by headless Firefox at 1400x900 (filed later from tmp/shared-memory)
- Commit: 8660325
- Filed: 2026-10-28 17:26 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/generate-buddy-levers` | f90fbe0bd68a2e7e |
| `scripts/generate-buddy-lever-map` | 46d9989e6a00e7f9 |
| `scripts/generate-buddy-lever-map-page` | bc148edf6a29a156 |
| `scripts/templates/buddy-lever-map.html` | 296c26ca871547a3 |
| `src/lua-basic/data/buddy-lever-map.lua` | 4af23e9e80cc9e36 |

## What changed since the previous picture
- `scripts/generate-buddy-levers`: first picture that names it
- `scripts/generate-buddy-lever-map`: first picture that names it
- `scripts/generate-buddy-lever-map-page`: first picture that names it
- `scripts/templates/buddy-lever-map.html`: first picture that names it
- `src/lua-basic/data/buddy-lever-map.lua`: first picture that names it

## What it shows
Left: the title Buddy lever map, a paragraph on what the dots are, a find box, '1414 levers, 19 segments, 1414 shown', and the segment list, each a coloured dot, its size and its label with an example sentence (bad check cold; work chopwood loot; agree disagree life; offer plead drop; ...). Right: a scatter of coloured dots on a pale panel: a dense mixed cloud left of centre (the emotes), an orange arc at top (steps), a blue cluster top right (hops), a pink cluster bottom right (the game's motions).

## The story so far
Separately, the same day, the owner asked for a semantic map for the buddies' AI: 'give them levers, create five hundred more, and then let them sort themselves into their world'. 1414 levers (small things a buddy can do with its body) were generated from the game's emote data; a local embedding model placed each by meaning, and the levers were cut into 19 automatically named segments, drawn here.
