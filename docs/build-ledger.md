# Build Ledger: Toward the Next Compile

The owner, 2026-10-30: "the next time we compile, we will have all of the
profile's issue files built. Can you start working on that? Building the
issue files that have no opened questions, or where they have a few
possible answers, can you build both and let me choose afterwards? Make
sure you keep careful accounting so we know what to prune."

This is that accounting, kept by hand by the agent as each piece is
built (the status board, `docs/next-compile-status.md`, written by
`scripts/issue-status-board`, says where every issue stands; this says
what this push added, how to switch it, and what to choose).

**How to read it.** Every row is one piece of work. *Switch* is how it is
turned on (everything new starts off). *Choice* is where both answers to
an open question were built: pick one, and the other can be pruned.
*Prune* says what to remove if the piece isn't wanted. *Waits* means the
server side is written, compiler-checked with borrowed flags, and
uncommitted until the owner's compile builds it.

## Before the push: what was already waiting

- The compiler check (`scripts/test-patched-syntax`) now reaches the buddy
  module even when the last build was another profile's: all of its
  files pass, the painted-map switch (617o7, 617o8), the army of 64
  (617e17) and the stand-in changes (617t) included.
- The board counts issues whose Current Behavior opens "syntax-checked" or
  "not yet built" as waiting (38 waiting, not 24).

## Built in this push

| Issue | What | Switch | Choice | Committed | Prune |
|-------|------|--------|--------|-----------|-------|
| 625a | which abilities each talent improves, from the game's own data: `scripts/generate-talent-touches`, `src/lua-basic/data/buddy-talent-touches.lua`, `docs/talent-touches.md`, the module's `buddies_talent_touches_data.h`; `scripts/test-talent-touches` | (data) | none | yes | the generator, its outputs and test |
| 625 | the talent weights and the weighted draw among a concern's answers: `buddies_talent_draw.h`, `tests/buddy-talent-draw/`, `scripts/test-buddy-talent-draw` (committed); `buddies_talents.cpp/.h` and their registration in `buddies_roam_strategy.cpp`, `buddies_loader.cpp` (waits) | `Buddies.TalentWeights` 0 off, 1 or 2 | **1** a fixed raise per talent point, or **2** the talent's own percent; and `Buddies.TalentWeights.Broad` **100** or **50** (a broad talent's share) | core yes, server waits | `buddies_talents.*`, the two registration lines, the draw header and its test |
| 617s2, 617s3 | the close follow: a ring round the leader at 4 yards, a tank at the front, the rest sharing places by nearness; "circle me" / "close follow" start it, "follow me" / "go away" end it: `RingPlaces`, `AssignRing` and the order words in `roam/buddy_follow_core.h`, checks in `tests/buddy-follow-core` (committed); the step and orders in `buddies_follow.cpp/.h`, `buddies_orders.cpp` (waits) | the order words; `Buddies.CloseFollow.InCombat` 0 or 1 | **0** the ring only when asked, or **1** also while the leader is in combat | core yes, server waits | the ring block in the follow step, the two order words, `RingPlaces` and `AssignRing` |
| 617s4 | `.buddy wider` (5 yards a step, up to 25) and `.buddy closer` (back to 5): the ring's radius per leader; the rule in `roam/buddy_follow_core.h` and its checks (committed); the commands in `buddies_follow.cpp`, their entries in `config/custom-gm-commands.lua` and the generated reference and help (wait) | the commands | none (the owner's numbers) | rule yes, commands wait | the command class, `RingRadius`, the two entries |
| 921, 921a | Alterac Valley under one shared sky: the shuffled weather deck, slush included, in `buddies_weather_deck.h` with `tests/buddy-weather/` and `scripts/test-buddy-weather` (committed); `buddies_weather.cpp` (every copy given the sky of the moment, `.buddy weather`), its registration and reference entry (wait) | `Buddies.AlteracWeather` 0 or 1 | none open (921's turn length and the storm's effects stay questions) | deck yes, server waits | `buddies_weather*`, the registration line, the entry |
| 921b | the wandering storm: `buddies_weather_storm.h`, the valley's cells (`scripts/generate-av-valley`, `buddies_av_valley_data.h`), the day-long test (committed); the storm in `buddies_weather.cpp` (waits); the weather page `docs/HTML/alterac-weather.html` by `scripts/generate-weather-page` (committed; picture 093) | the parent's `Buddies.AlteracWeather` | none (921b's size and count stay questions) | walk yes, server waits | the storm parts of `buddies_weather.cpp`, the storm header, valley data and generator, the page |
| 617s5 | sidesteps round the target after an instant spell: `buddies_sidestep.h`, `tests/buddy-sidestep/`, `scripts/test-buddy-sidestep` (committed); `buddies_sidestep.cpp` and its registration (wait) | `Buddies.Sidestep` 0, 1 or 2 | **1** a share of the circle (melee 20-35%, ranged 10-20%) or **2** by distance (2-3 yards at 40 yards, less closer) | arithmetic yes, server waits | `buddies_sidestep*`, the registration line |

## Choices waiting for the owner

1. **Talent weights** (625, question 1): `Buddies.TalentWeights = 1` (each
   talent point raises an ability 6%) or `= 2` (as much as the talent's
   own stated percent, the per-point raise where it states a flat
   amount).
2. **Broad talents** (625a, question 1): `Buddies.TalentWeights.Broad =
   100` (a talent for "all your Shadow spells" counts on each in full) or
   `= 50` (half).
3. **The close follow in combat** (617s2, the two readings of "in combat
   or when specified"): `Buddies.CloseFollow.InCombat = 0` (the ring only
   when asked) or `= 1` (also while the leader fights).
4. **Sidesteps** (617s5, the owner's two step sizes): `Buddies.Sidestep =
   1` (a share of the circle) or `= 2` (by distance).

## Waiting for the owner's compile: the files

All pass the compiler check (`scripts/test-patched-syntax`, flags borrowed
from the bot module where the buddy module was never built here). Kept
uncommitted until the compile builds them, then committed with their
issues.

| File | For |
|------|-----|
| `buddies_path.cpp/.h`, `buddies_map_stream.cpp` | the painted-map pathfinding switch (617o7, 617o8) |
| `buddies_army.cpp/.h`, `buddies_stand_ins.cpp`, `buddies_stand_ins_pick.h`, `buddies.h`, `buddies_party.cpp`, `buddies_gems.cpp`, `buddies_roam_ground.cpp` | the army of 64, fully random; stand-ins met by chance; grouping; gems by plan (617e17, 617t, 617c2) |
| `buddies_talents.cpp/.h`, `buddies_roam_strategy.cpp` | the talent draw (625) |
| `buddies_follow.cpp/.h`, `buddies_orders.cpp` | the close follow's ring and its radius (617s2-s4) |
| `buddies_weather.cpp` | Alterac Valley's sky and storm (921) |
| `buddies_sidestep.cpp` | sidesteps (617s5) |
| `buddies_loader.cpp` | registers the new scripts |
| `config/custom-gm-commands.lua`, `docs/gm-commands.txt`, `docs/HTML/gm-commands.html`, `sql/*/34-custom-command-help.*.sql` | `.buddy path`, `.buddy army`, `.buddy wider`, `.buddy closer`, `.buddy weather` described |

## Not built, and why

Kept as each candidate is looked at.

| Issue | Why not (yet) |
|-------|---------------|
| 617s1 | compass directions per roster slot: the ring shares places by nearness instead; build if the owner wants each buddy to keep its own compass point |
| 921 (sliders) | the weather page's sliders for turn length, storm size and pace: would need the arithmetic twinned in the browser; the page plays back the real numbers instead |
| 617s6 | moved to the custom client as its issue 815 (2026-10-30): the click is what the original client can't send |
| 617a7 | resetting a buddy touches Sargobras's dialogue, the roster and character creation: next, a larger piece |
| 617e18 | buddies pointing to the next quest: large (the server's quest tables, the arc in open country, where buddies roam rather than follow) |
| 625c, 625d | every tree's list in the trees' shares, and the moment's economy: large, next after the talent draw is seen in game |
