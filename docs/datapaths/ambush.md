# Data path: the ambush

*How a monster gets from the world database to a player's back on beta,
and how the design got here. Written 2026-10-17. The code is
`src/lua-beta/ambush.lua` (summary: `ambush.info.md` beside it); its
offline test is `scripts/test-ambush`.*

## The path, in order

1. **Login** (`Ambush.setupPlayer`). The player's two queues are emptied,
   their ambusher count set to 0, and their clock started: 30 seconds of
   grace after 10 or more minutes away, otherwise one step of the walk.
   Bots get all of this too (wanted: they live in the same world).
2. **The clock** (`Ambush.spawnAndAttackPlayer`, one tick). It books the
   next tick first, by the random walk (`Ambush.getNextInterval`: the last
   interval plus or minus 2, 3 or 4 seconds, never under 10, pulled back
   down above 100 and 200). The interval is remembered by character
   (`AmbushMemory`), because the per-object store is wiped at logout.
3. **The holds** (`Ambush.HOLDS`). Sitting, dead, swimming, three already
   chasing, a rare's fight: any one of them skips this tick.
4. **The queues.** Each player has a normal queue and a rare queue, lists
   of creature entry numbers (up to 8). Normal empty and rare empty: ask
   for rares (rare elites for a group of 3+). Normal empty, rare holding
   something: spawn the rare, ask for normals. Normal holding something:
   spawn from it.
5. **Asking the world database** (`Ambush.setupAmbushQueue`, asynchronous).
   One question: creatures of this rank whose level range holds the
   player's level, with loot, no NPC flags, of the "ambush" types
   (dragonkin, demon, elemental, giant, undead, mechanical, aberration).
   The answer comes back later to the player who asked, looked up by name
   (issue 210). A rank with nothing for the level asks the next one down:
   rare elite, then rare, then normal (`Ambush.NEXT_RANK_WHEN_NONE`).
6. **The spawn** (`Ambush.randomSpawn`). 120-160 yards out: in an arc
   ahead of a moving player, on a plus sign round a still one. Water:
   up to 3 retries round the player. A cliff (ground 15+ yards above or
   below the player) or no ground: up to 5 retries, each nearer, never
   under 30 yards. Then the monster is counted against its player.
7. **The chase** (`Ambush.chasePlayer`, every second). It walks to the
   midpoint between itself and the player each step. The player sitting:
   it circles them with aggro off. The player standing again: aggro back
   on (issue 305). Close or fighting: it attacks. The player logged out:
   it goes. Across a map border: it goes, and is sent again on the
   player's map. Too far: it goes.
8. **The fight** (`Ambush.inCombatCheck`, every half second). Still
   fighting: look again. Over, monster alive: back to the chase.
9. **The end** (`Ambush.layToRest` on death, `Ambush.despawn` otherwise).
   Off the count exactly once, timers stopped, the last move cancelled so
   the corpse stays where it fell, data cleared (issues 304, 305). Normal
   corpses go 6 minutes after death; rares' stay until a restart.

## The data it keeps

| Where | Name | What (type) |
|---|---|---|
| player | `"queue"`, `"rare-queue"` | creature entries (list of numbers) |
| player | `"num-ambushers"` | monsters counted against them (number) |
| player | `"is-in-boss-fight"` | a rare of theirs is alive (boolean) |
| script | `AmbushMemory[guid low]` | `{ interval = ms, logoutTime = unix seconds }` |
| monster | `"ambush-chase-target"` | its player's guid |
| monster | `"is-rare"`, `"ambush-counted"` | booleans |
| monster | `"wander-radius"`, `"ambush-max-distance"` | yards (numbers) |
| monster | `"orbit-direction"` | 1 or -1 |

## How it got here: two lines that split in April

The ambush has a history of variations, and two of them ran side by side
for a while. Knowing which is which explains most of the older issues.

**wow-chat-1** (`libs/wow-chat-1/ambush.lua`, the owner's original). A
separate scheduler (`periodic_events.lua`) kept time: every 21 seconds it
asked the holds and then called the ambush, which only spawned. The
answer to the queue question was handed to every player in the world (one
player's answer filled everyone's queues where the levels fitted; issue
210 later). A rank with nothing for a level simply ended there, so a
player below level 6 (no rares of these types exist there) never met an
ambush at all.

**January 2026** (this project's first copy, 86b61b3, the owner's later
version of wow-chat-1). A placeholder and a one-second retry were added
for "nothing found", so low-level players got normal monsters; harmless
while the scheduler kept time.

**Line A: the 2026-03-31 stash, live today.** The random walk (issue 303)
and the ambush booking its own next tick (302: nothing was starting the
cycle) were made here. Booking its own ticks is what turned the January
retry into a second clock: each "nothing found" started one more, so a
new character's clocks multiplied (found and fixed 2026-10-17; the cause,
rare-free levels, is now answered by asking the next rank down). The
scheduler's holds were not carried over, so the ambusher count was kept
but never read (restored 2026-10-17). Issue 210 (2026-05-20) made the
question per-player and asynchronous here.

**Line B: 2026-04-04 to 04-09, switched off since 04-10**
(`src/lua-beta/ambush.lua.disabled`). This line ran under the scheduler
and tried other answers:
- *A creature cache at startup.* All creatures for levels 1-20 read once
  when the script loads, so no question is asked while playing. The reason
  given in the file: a buffer corruption in the engine's database query
  call (open issue 141, the query-formatting dangling pointer). Line A's
  asynchronous question, made later by 210, is the other answer to the
  same worry; both work, and the cache would also have avoided the
  rare-free-level problem by never asking.
- *Death cleanup and the corpse fix* (issues 304, 305), ported to line A
  on 2026-10-17 as `Ambush.layToRest`.
- *Its own variant of the fight check*, letting the game's own monster AI
  carry on when another player is fighting the monster.

On 2026-04-10 every custom script was switched off for the profile
baseline, and line B's file was renamed `.disabled`. Line A came back by a
merge from the alpha branch, which is why the live file lacked B's work.

## Checking it

- `scripts/test-ambush` plays every step above in a pretend world
  (`scripts/lib/toy-world.lua`), including each fix of 2026-10-17 and the
  ports from 304 and 305; it fails if any of them is taken out.
- `scripts/test-beta-lua-load` loads the file the way the engine does.
- In game: issue 302 is closed by watching it work.

## Related

Issues 210, 302, 303, 304, 305, 309 (monsters that test their foes), 141
(the query bug behind line B's cache); `docs/profiles/beta-roadmap.md`.
