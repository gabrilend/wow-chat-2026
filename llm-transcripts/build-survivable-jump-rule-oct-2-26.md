# Conversation Summary: agent-a1e66b066097821fd

Generated on: 2026-10-02 17:05:43
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Your directive: Build the answered "Fall damage on a jump" rule in
issues/617e8-following-across-maps.md (read it fresh): a buddy jumps after its
owner only when the fall to the ground below its landing point would leave it
alive at current health (compute with the server's own fall-damage formula —
find it in source-beta, Player::HandleFall / EnvironmentalDamage, including
basic's 10× fall-damage config multiplier as actually applied, and any
safe-fall modifiers the buddy has), or when water deep enough to negate fall
damage (find the server's rule for when landing in water cancels fall damage)
lies within the jump's horizontal reach — then it aims its jump at that water.
Otherwise it stays aboard and follows by riding round (the existing path). Use
map height/liquid queries (Map::GetHeight, GetLiquidData or equivalent) to test
candidate landing points; sample a few points within reach toward the owner
first.

Files you may edit: modules/mod-buddies/src/buddies_crossing.cpp/.h,
docs/balance-updates.md (append; tunables with reasons), issue 617e8 (Current
Behavior to the true state). Another builder is concurrently editing
buddies_loyalty.cpp / a new whisper file / buddies_loader.cpp / issue 617a5 —
don't touch those.

Style: match module code. No nil fallbacks; loud errors. Verification: no
builds. -fsyntax-only with buddies_login.cpp's command from
build-shadow/compile_commands.json (file swapped, no cd), logs under
tmp/shared-memory/. Do not commit. Report: what players see, files, test
results, numbers, unbuilt, open questions.

--------------------------------------------------------------------------------

### Assistant Response 1

> Task: make buddies jump after their owner only when the fall is survivable or
> there's deep enough water within reach to aim for.

> Bots only take fall damage when code calls the fall handler for them; normally
> only a real client's landing report triggers it. Checking what the existing
> jump code does:

> Bots never report a landing, so the server's fall handler never runs for a
> buddy's jump; I'll apply it by hand on landing, the same way the bot module
> does. Now the code:

> Now the landing judgement and the rewritten jump:

> Now applying the fall on landing, outside the crossing's lock (dying runs
> other hooks, which could take the same lock):

> It passes with no warnings. Now the balance log and the issue:

Task: buddies jump after their owner only when the fall is survivable or there's
deep enough water to aim for. Done. It passes a syntax check (exit 0, no
warnings). Not compiled, not tried in game, not committed.

**Bug found and fixed:** a buddy's jump never took fall damage at all. The
server only runs its fall handling when a real client reports a landing, and
bots have no client. So until now a buddy could jump off a zeppelin unhurt. On a
ground landing the server's own fall handling is now run for the buddy by hand,
the same way the bot module handles a forced dismount. A deep-water landing
deals nothing.

**What players will see:** when you jump off a moving ship, each buddy judges
where it could land:
- **Deep enough water:** it aims for it and lands unhurt. "Deep enough" is the
  server's own swimming depth.
- **No water, but a survivable fall:** it takes the gentlest such landing.
  Survivable is judged by the server's own fall-damage formula at basic's 10×
  rate, against its current health. Feather Fall, Safe Fall, Divine Protection,
  Gust of Wind and immunity all count, the same as for a player.
- **Neither:** it stays aboard and rides round, and the log says how many
  landings would have killed it. If no ground at all is found below, that's an
  error, with what to check.

**Files:**
- `modules/mod-buddies/src/buddies_crossing.cpp`:
  - new tuning: the landing points, a 1,000-yard search downward, and the
    fall-damage constants copied from the server's fall handler;
  - new functions: one computing the fall damage, one picking the landing, and
    the jump itself rewritten;
  - the landing applies the fall outside the crossing's lock, because a fatal
    fall runs death hooks;
  - two new includes for the world's fall-damage rate.

  I claimed the file whole because I added the includes with sed.
- `docs/balance-updates.md`: new entry.
- `issues/617e8-following-across-maps.md`: Current Behavior updated. The
  validator is clean.

**Numbers (in the balance log):**
- 25 landing points: toward you first, then 30° and 60° either side, at 8, 14,
  20, 26 and 32 yards.
- A point counts only within a running jump's carry for its own drop: 8 yards
  plus run speed × fall time.
- The first deep-water point wins. Otherwise the survivable landing with the
  least damage.

**Not built:** absorb shields and armor-based reductions inside the server's
damage step aren't counted, so the survivability judgement is slightly cautious.

**Open questions:**
1. Should a buddy also refuse a fall that's survivable but leaves it nearly
   dead? The rule as built is strictly "survivable", so 1 health left counts.
2. The copied fall-damage constants have to be kept in step if upstream changes
   the fall handler. That's noted in a code comment; should it get a test
   instead?

--------------------------------------------------------------------------------

