# Custom ID Ranges

How the project numbers the database rows it adds (creatures, their
spawns, game objects, texts), so its rows never collide with the stock
game's or with each other's.

## The rule

**An issue's rows are numbered from its issue number times 10,000:**
issue 617 uses 6,170,001 to 6,179,999; issue 718 uses 7,180,001 onward.
The same block serves every table: creature 7180001, its spawn 7180001,
its texts 7180001 to 7180003. Tables have separate numbering, so sharing
the block across them is safe, and it keeps an issue's rows easy to find
and to delete on revert (`BETWEEN 7180001 AND 7189999`).

## Why 10,000, not 100,000

The server keeps the next free creature and game-object *spawn* number at
the highest spawn number in the database plus one, and **stops the whole
world at startup** the first time it hands one out at or past 16,777,215
(the largest 24-bit number: "Creature spawn id overflow!! Can't continue,
shutting down server", TCE00007). A world with a spawn numbered past the
cap boots to "ready" and then halts.

The earlier habit, issue times 100,000, fits only for issues below 168
(167 x 100,000 = 16,700,000). Issues 617 and 718 went past it (61.7 and
71.8 million) and halted every boot until they were renumbered,
2026-09-29. Issue times 10,000 fits for every issue up to 1,677.

Rows numbered the older way below the cap (issue 155's, from 15,500,001)
stay as they are. They do push the highest spawn number, and so the next
number handed out at runtime, up to about 15.5 million; about 1.27 million
remain before the cap.

## The check

`scripts/validate-basic-state` fails on any creature or game-object spawn
numbered at or past 16,777,215. Run it after any SQL that adds spawns;
it prints the current highest numbers only through its failures, so for
the headroom itself ask the database:
`SELECT MAX(guid) FROM creature` (and `gameobject`).
