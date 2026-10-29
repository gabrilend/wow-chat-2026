# 077-ground-sandbox-owner-burning-steppes

## What made it
- the owner's screenshot in Firefox of docs/HTML/archive/ground-sandbox/2026-10-28-2306-070d6d0.html (filed from the conversation's image 47)
- Commit: 69a18f2
- Filed: 2026-10-29 13:24 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | d6ac2d9f64012a90 |

(That fingerprint is the template as it stood when the picture was filed,
not the page photographed: the picture is of the archived page
`docs/HTML/archive/ground-sandbox/2026-10-28-2306-070d6d0.html`, made from
the template as of commit 070d6d0. Read "what changed" below with that in
mind.)

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: unchanged since 076-ground-sandbox
  (the template's latest; the page in this picture is the older 070d6d0
  version, before the five ways, the orbit's mend and the painted map)

## What it shows
The owner's own screenshot (2026-10-29, in Firefox under dwm) of the archived ground sandbox version 2026-10-28 23:06, commit 070d6d0 ("Stuck bots back out first, twice as far each time, until past their forwardmost stuck spot"): docs/HTML/archive/ground-sandbox/2026-10-28-2306-070d6d0.html. That version predates the five ways, so the panel has no Pathfinding row: every bot walks by orbit. Settings: Eastern Kingdoms, theme grey patchwork, 36 bots, 4x, turning clockwise, no formation, steepest 50 degrees, stuck check 1 s, ground hills and blocks. The area: Burning Steppes, the fence of Firegut Ogre Mage, Firegut Brute, Firegut Ogre and Gorgon'och (59 spawns, 47,569 square yards walkable), drawn as several overlapping yellow fences over red steep ground, lilac sub-zones, dark doodads and two orange ones the bots were shown; the white player dot near the middle. Most of the bots (green dots, each in a cyan orbit ring) are bunched in a knot along a narrow ledge north-west of the middle, between steep ground. The panel: spacing 5.3 yards (median nearest), fence covered 18%, turned aside 69.1 steps a second, stopped 34.1, stuck 154 times with 154 back-outs (736 yards), orbits 151 begun, 5 left by sight, 109 turned round, 9 steps refused by the world, out of dead ends 23, mapped 7%, 15 peninsulas found and 5 bots exploring them.

## The story so far
The ground sandbox (617e16) put bots on real ground; on 2026-10-28 the owner's stuck rule (back out twice as far, then orbit round) was built, and this picture, kept by the owner the next day from that version's archived page, shows what it then did on a cramped ledge: a knot of bots each circling in its own small ring. On 2026-10-29 the buddy module's offline test found why: orbit turned in toward the obstacle every step whether it felt it or not, and walked rings three yards across; it was mended (pictures 065, the module's 121 steps round a wall from 269), and the painted map (617o8) followed, with no bot stuck in the same comparison.
