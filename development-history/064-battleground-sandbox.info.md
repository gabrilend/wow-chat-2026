# 064-battleground-sandbox

## What made it
- scripts/generate-battleground-sandbox-page --screenshot 'sim=180&side=15' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/battleground-sandbox.html#sim=180&side=15)
- Commit: 23aab26 (with uncommitted changes to its sources)
- Filed: 2026-10-29 11:44 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/battleground-sandbox.html` | d702e16ee2ee6813 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-battleground-sandbox-page` | 40cc80d96b25a32f |
| `src/lua-cc-test/data/arathi-basin-roads.lua` | f072f87fd6accd3b |

## What changed since the previous picture
- `scripts/templates/battleground-sandbox.html`: first picture that names it
- `scripts/templates/ground-decode.js`: unchanged since 063-ground-sandbox
- `scripts/generate-battleground-sandbox-page`: first picture that names it
- `src/lua-cc-test/data/arathi-basin-roads.lua`: first picture that names it

## What it shows
he first battleground page (617e16l): Arathi Basin from above after 3
minutes of play, 15 a side. The ground is shaded dark green with steep
ground in brown bands (most of the field's edges and the ridges between
bases); doodads are dark squares. The bot module's 15 roads are thin gold
lines between the seven places; the Horde's home was drawn north-west,
the Alliance's south-east this match. The Stables and the Lumber Mill are
filled red (Horde), the Farm blue (Alliance); a blue arc is closing round
the Gold Mine and the Blacksmith (Alliance assaults). Small groups of dots
(blue Alliance, red Horde) fight near the Gold Mine and the Farm, with
thin lines to their foes; single dots walk the roads. The panel: Alliance
80 of 1600 with 1 base, Horde 100 with 2; in play 16 and 17 (tanks added
for bases taken); fighting 10 and 7, orbiting 9 and 4, guarding 2 and 2,
kills 3 and 5, broke off 4 and 17. At this zoom the bots are small beside
the field: the place labels and roads read, the bots barely.

## The story so far
he ground sandbox (617e16) put bots on the world's real ground and
compared five ways to find a path (617o7), built again for the game with
an offline test whose faults (corner cutting) were then mended on the
page (062-063). The owner then asked for the battleground designs (176a2:
squads, roads taken in turn; 629: fronts) to be seen playing, two sides,
as the bots would: orbiting foes at their range, leaning from bunched
enemies toward allies, breaking off to the objective. 064 is the first
picture of that page.
