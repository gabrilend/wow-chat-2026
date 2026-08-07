# 412 - Dynamic Questing Prototype: the Class Unlock Quests

## Status
- Created: 2026-08-07
- Phase: 4 (per user direction; see Open Questions on the fit)
- Supersedes the decision in: 701 (quest-spells-to-trainers)
- Blocked by: 210 (per-player ambush queue)
- Priority: Medium — this is a design reversal plus a new system, not
  a repair. Nothing is broken while it waits.

## Source Report (verbatim, 2026-04-02)

> Also, I changed my mind for the unlock quests. Can we make them a prototype for
> the upcoming dynamic questing system, in phase 4? For now, we can let them be a
> prototype. How it'd work is when they're the right level (and every level after
> that, until they learn the spell) the NPC with the quest will spawn as one of
> their travellers. Then, once they have the quest, the monsters for that quest
> will spawn amongst their ambush-queues - for every time it's regenerated,
> exactly one of the monsters will take the place of one other monster. If the
> player has two such quests, then two monsters will be replaced, one of each
> type per queue. Then, once the quest is complete (and only then) the
> quest-giver will respawn (unless they're already in the traveller banks, in
> which case they can spawn normally from that too. If a quest doesn't need
> monsters but instead needs other things, like items or whatever, then those
> will be forcefully added to the loot tables of 1 of the monsters in the ambush
> queue, and when being looted they will always go to that player, even if
> another player fully tags and kills the monster,

## What Changed

Issue 701 solved a problem: the world is empty, so the quest NPCs that
normally teach Bear Form, Summon Voidwalker, Tame Beast, Defensive
Stance, and the poisons do not exist, and those abilities become
unreachable. 701's answer was to delete the quest as a step and move
the spell onto a class trainer. That answer works and it shipped.

The reversal is that the quest was never the obstacle — the *static
world* was. A quest giver standing in a fixed town that no longer has
towns is unreachable. A quest giver who walks up to you is not. Once
the traveler system exists, keeping the quest costs nothing and buys
back the thing 701 threw away: earning the ability instead of
purchasing it.

So these seven or so class unlock quests stop being an obstacle to
route around and become the **prototype** for dynamic questing —
the first case of the general pattern where a quest finds the player
rather than the player finding the quest.

## The Pattern in One Sentence

Every static piece of a quest — the giver, the target monsters, the
required drops — gets re-expressed as an injection into a stream the
player already has flowing past them.

| Static WoW | Everland Ghostsong |
|---|---|
| Quest giver stands in a town | Quest giver arrives in the traveler stream |
| Quest monsters live in a fixed zone | Quest monsters are substituted into the ambush queue |
| Quest items drop from those monsters | Quest items are force-added to one queued monster's loot |
| Turn-in NPC waits where you left them | Turn-in NPC returns to the traveler stream on completion |

The player's experience is that the quest comes to them, follows
them, and leaves when it is done. There is no travel, no zone, no
looking anything up.

## Mechanics

### 1. Quest-giver injection into the traveler stream

**Eligibility.** A player is eligible for an unlock quest when they
are at or above the quest's level *and* have not yet learned the
spell it teaches. The report is explicit that eligibility persists —
"when they're the right level (and every level after that, until they
learn the spell)" — so a player who misses the giver at level 10 is
still eligible at 14. There is no missable window.

**Spawn.** While eligible, the quest NPC becomes one of the
candidates the traveler system draws from for that player. It is not
a guaranteed next-traveler; it enters the pool, so the giver's
arrival is a pleasant accident rather than a scheduled appointment.

The dynamic trainer spawning from 503 already does exactly this
shape of thing — a class-appropriate NPC selected per-player and
inserted into the traveler stream. The quest giver is the same
mechanism with a different selection predicate.

### 2. Monster substitution into the ambush queue

Once the player has *accepted* the quest, the quest's target
creatures start appearing in their ambushes.

The substitution rule from the report is precise and worth keeping
exactly as stated: **every time the queue is regenerated, exactly one
of the queued monsters is replaced by one quest monster.** Not
appended — replaced. The ambush cadence and the queue length do not
change; what changes is that one slot in each regenerated queue now
holds something that matters.

With two active quests, two slots are replaced, one per quest type.
The rule generalizes as one substitution per active quest per
regeneration, which naturally caps the dilution: a player carrying
four unlock quests has four of their queue slots spoken for and the
rest still random.

This is the piece that **cannot be built until 210 lands.** The
current ambush queue fills by broadcasting query results to every
player in the world, because the async callback lost track of who
triggered it. Per-player injection is impossible against a broadcast
queue — 210 names this exact feature as the thing it unblocks.

### 3. Item objectives: forced loot, bound to the asker

For quests whose objective is an item rather than a kill, the
required item is force-added to the loot table of **one** monster in
the player's ambush queue.

The ownership rule is the interesting part: **the item goes to the
quest holder even if another player tags and kills the monster.**
This is deliberately not how WoW loot works, and it is deliberately
not how the treasure-chest system (402) works either, where the
holder cannot see their own chest and needs a second player to
retrieve it. Quest loot is the opposite: it cannot be intercepted,
because a quest objective that another player can accidentally
consume is a quest that breaks in groups.

So there are now two distinct loot-routing policies in the project,
and they mean opposite things on purpose. Treasure is social because
sharing it is the point. Quest items are private because losing them
is a dead end.

### 4. Completion and the return of the giver

The turn-in NPC reappears in the traveler stream **only after the
quest's objectives are complete.** Before that, they are not in the
pool — so a player carrying an unfinished quest does not keep
bumping into the person waiting for it, which would make the world
feel small.

The one exception in the report: if the NPC is already in the
player's traveler bank for ordinary reasons, they can also spawn
normally from that. Being a quest giver adds a spawn condition; it
does not remove the ones the NPC already had.

## Scope of the Prototype

The unlock quests from 701, which are the ones that gate class
identity:

| Class | Unlock | Level |
|---|---|---|
| Druid | Bear Form (+ Growl, Maul, Demoralizing Roar) | 10 |
| Druid | Aquatic Form, Travel Form | 16 |
| Druid | Cat Form (+ Claw, Rip, Prowl, Cower) | 20 |
| Warlock | Summon Voidwalker | 10 |
| Warlock | Summon Succubus | 20 |
| Hunter | Pet chain — Call Pet, Revive Pet, Tame Beast, Feed Pet, Dismiss Pet | 10 |
| Shaman | Totem quests — Earth, Fire, Water, Ghost Wolf | 4–20 |
| Warrior | Defensive Stance, Taunt, Sunder Armor | 10 |
| Rogue | Deadly Poison, Crippling Poison | 20 |
| Paladin | Redemption | 12 |

701's full table with spell IDs is the authoritative list.

Out of scope for the prototype: the general quest corpus. Thousands
of ordinary WoW quests exist in `quest_template` and this design does
not attempt to make them all dynamic. The prototype is deliberately
one small, well-understood, high-value set — enough to prove the
four mechanics work together and to surface what the general system
would need.

## What 701's Work Becomes

701 already shipped `quest-spells-to-trainers.sql`, which puts these
spells on trainers. That does not have to be undone to build this.
The two can coexist during the prototype: the trainer route stays as
the guaranteed path, and the quest route is the interesting one. If
the prototype proves out, the trainer entries for the unlock spells
come back out and 701 gets updated to say why.

Keeping both during the prototype also means a failed quest injection
never leaves a class unable to function — the trainer is still there.
That is a deliberate safety net, and it is the kind of thing that
should be removed once it stops being needed rather than left in
place forever.

## Suggested Implementation Steps

1. Land 210 (per-player ambush queue). Nothing here works without it.
2. Build the eligibility query — given a player, which unlock quests
   are they at-or-above level for and have not yet learned the spell
   from. This is a join against `quest_template`, the player's known
   spells, and the 701 spell table.
3. Extend the traveler selection to consult the eligibility list and
   add eligible quest givers to that player's candidate pool.
4. Extend queue regeneration with the substitution rule: for each
   active unlock quest, replace one queue entry with one of the
   quest's target creatures. Keep the queue length fixed.
5. Build the forced-loot path for item objectives — inject the item
   into one queued creature's loot and bind the award to the quest
   holder rather than the tagger.
6. Add the completion condition to the traveler pool so the turn-in
   NPC returns only when objectives are met.
7. Test one quest end to end, ideally Druid Bear Form at level 10:
   the giver arrives, the quest is accepted, bears start appearing in
   ambushes, the objective completes, the giver returns, the form is
   learned.
8. Test the group case — a second player kills the quest monster and
   the item still routes to the quest holder.
9. Test the two-quest case — a shaman with two open totem quests sees
   one substitution of each type per regeneration.

## Cross-References

- `issues/701-quest-spells-to-trainers` — the decision this reverses,
  and the authoritative table of which spells come from which quests
  at which level.
- `issues/210-ambush-per-player-queue.md` — the blocker. Its "Why
  This Is a Problem" section names this feature explicitly.
- `issues/503-dynamic-trainer-spawning` — the completed precedent for
  selecting a per-player NPC and inserting it into the traveler
  stream. The quest giver is the same mechanism, different predicate.
- `issues/505-creature-class-travelers.md` — the traveler pool the
  giver joins.
- `issues/402-treasure-chest-shared-loot.md` — the opposite loot
  policy, deliberately. Worth reading alongside this one.
- `src/lua-beta/ambush.lua` — the queue this substitutes into.
- `src/lua-beta/travel.lua` — the traveler stream the giver enters.

## Open Questions

- **Does phase 4 fit?** The report says phase 4, and that is
  honored here. But phase 4's stated effect is "Loot circulates /
  Treasure," and this feature pulls hardest on phase 3 (the ambush
  queue) and phase 5 (travelers). The forced-loot mechanic is the
  only genuinely phase-4 piece. Either the phase assignment wants
  revisiting, or dynamic questing wants a phase of its own.
- **What counts as "the monsters for that quest"?** Some quests name
  a creature entry directly; others want a creature that drops a
  specific item, or a creature in a specific zone. The zone-scoped
  ones have no meaning here, since the ambush queue ignores geography.
  Needs a per-quest decision for the ten in scope.
- **What happens to a quest whose objective is unreachable by
  substitution?** Escort quests, "speak to X," "use item at
  location." None of the ten in scope appear to be of this kind, but
  the general system will hit them.
- **Is one substitution per regeneration enough to feel like
  progress?** If a queue regenerates every ~40 seconds and a quest
  needs eight bear kills, that is several minutes of ambient play. It
  might feel right, or it might feel like the quest is barely
  happening. This is a number to tune after the first playtest, not
  before.
- **Should the giver's arrival be announced?** A traveler walking up
  is easy to miss while fighting. Nothing in the report asks for a
  notification, and adding one would cut against the "pleasant
  accident" framing — but a player who misses the giver three times
  in a row will not read it as an accident.
- **How does this interact with playerbots?** Bots run through the
  same ambush and traveler systems. A bot that accepts an unlock
  quest and never completes it would hold a substitution slot
  indefinitely. Bots may need to be excluded from eligibility, or
  taught to complete.
