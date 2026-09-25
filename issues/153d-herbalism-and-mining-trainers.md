# 153d - Herbalism and Mining Trainers

## Status
- Created: 2026-09-03
- Phase: 1
- Parent: 153
- Depends: 153a (the profile), 153b (an emptied world), 503 (the travel
  system's trainer normalisation, completed)

## Origin

> [a] "explore" profile which just has wowchat spawn profession trainers for
> herbalism and mining

## Current Behavior

**The travel system knows nothing about professions.** Counted against the
world database, the 279 creature ids named in `travel.lua`'s tables resolve to
123 class trainers, one weaponsmith, and no profession trainer of any kind.
There is no alchemy, blacksmithing, enchanting, engineering, leatherworking,
tailoring, herbalism, mining, skinning, cooking, first aid or fishing trainer
anywhere in the pool, and no category that would hold one. The ten categories
are Ammo, Innkeepers, Trainers, Consumables, Poisons, Others, Melee, Ranged,
Armor and Food; "Others" is five novelty vendors.

**The travel system is also not running.** `travel.lua` is filed as
`travel.lua.disabled`, and the vanilla profile's Lua directory does not contain
it in any case. Turning it on for explore is part of this issue's work, not an
assumption it can make.

**The trainers themselves exist in the world database and are plentiful.**
Querying by subname:

```sql
SELECT entry, name, subname FROM creature_template
WHERE  subname IN ('Herbalism Trainer','Mining Trainer')
ORDER  BY subname, entry;
```

returns dozens of each, across both factions and every starting zone, plus two
generic entries named "World Herbalism Trainer" and "World Mining Trainer" that
look purpose-built for exactly this use. Several rows are prefixed `[UNUSED]`
and should be filtered out.

## Intended Behavior

Two trainers wander the world, and they are the only people in it.

A herbalism trainer or a mining trainer walks into view, on the travel
system's ordinary schedule, teaches what a gathering trainer teaches, wanders
off and despawns. Which of the two arrives is a coin flip. Nothing else in the
traveller pool is enabled — no vendors, no innkeepers, no class trainers.

### How the travel system delivers them

The machinery is already right and needs a new category rather than new code.
`Travel.travellers` is a table of named categories, each holding a list of
`{id, minLevel, maxLevel, rel}` entries and a `typeMask` bit;
`Travel.getTravelerTypeMask` returns the mask of categories a given class may
receive; `Travel.updatePlayerTravellers` filters every category's list by
faction and level into a per-player bag, and `Travel.getRandomTravellerId`
draws from that bag with `table.remove`, so each traveller appears once until
the bag empties and regenerates.

So this issue adds one category — call it Gathering — holding the herbalism and
mining trainer entries, and on the explore profile `getTravelerTypeMask`
returns *only* that category's bit, for every class. The nine existing
categories stay in the file and are simply never selected. Nothing is deleted,
and beta's behaviour is unchanged.

The faction field matters. `rel` is 1 for horde-friendly, 2 for
alliance-friendly, 3 for both, and `Travel.isValidFaction` enforces it. The
trainer list has to carry the right value per entry or a player will be
approached by someone who will not speak to them.

### The timing, which is inherited

`periodic_events.lua` registers a traveller clock per player on login at
`DELAY_PERIODIC_SPAWN_TRAVELLER`, currently a flat 130 seconds — unlike the
ambush interval, which random-walks. Each firing re-registers itself and calls
`Travel.spawnAndTravel`, skipping silently if the player is dead, swimming or
sitting. The traveller spawns 30 to 45 yards away, walks a course away from
the player, wanders on a 2-to-4-second step, mirrors the player's sit state,
and despawns after five minutes or when no player is within 200 yards.

Whether 130 seconds is right for a profile where the trainer is the only
person you will meet all day is a balance question, not a mechanism one, and
belongs in `docs/balance-updates.md` once someone has walked around for an
hour.

## Suggested Implementation Steps

1. **Symlink the travel system into explore — settled 2026-09-04.**
   `travel.lua`, `movement.lua` and `periodic_events.lua` are symlinked from
   the beta corpus into `src/lua-explore/` rather than copied or refactored
   apart:

   > we can do symlink, and let the upstream handle patches to that branch.

   Beta is upstream for these files. Explore takes what beta has, and when beta
   changes them explore inherits the change without anybody merging anything.
   The cost is that a beta change can break explore silently, and the mitigation
   is that explore's boot check has to actually exercise the traveller path
   rather than just starting the server. The alternative — splitting the shared
   movement and scheduling out into a third thing both import — was the
   *correct* answer by dependency hygiene and the wrong one by effort, and it
   stays available if the symlink starts hurting.

   What explore does *not* inherit is which clocks get registered.
   `periodic_events.lua` registers ambush, traveller and treasure; explore wants
   the traveller clock only. That is a profile-conditional inside the shared
   file, not a fork of it.

2. **Build the trainer list from the database, not by hand.** Query the
   herbalism and mining trainers, filter out `[UNUSED]` rows, resolve each
   one's faction from `creature_template.faction`, and emit the Lua table. A
   hand-typed list of forty entries will have a wrong faction in it and nobody
   will notice until a tauren meets a Stormwind herbalist.

3. **Decide between the specific trainers and the two "World" entries.**
   `World Herbalism Trainer` and `World Mining Trainer` are single neutral
   entries that would make the list two rows long and remove the faction
   problem entirely, at the cost of every trainer being the same nameless
   person. The named ones give the world texture. This is a taste decision
   and it should be made by looking at both.

4. **Add the Gathering category** to `Travel.travellers` with an unused
   typeMask bit, and make `getTravelerTypeMask` return only that bit when the
   profile is explore.

5. **Confirm the trainers can actually teach.** A trainer NPC teaches from its
   `trainer_spell` rows via the `trainer` table, gated by
   `Trainer::IsTrainerValidForPlayer` — for a tradeskill trainer the gate is
   "does the player already know the required spell". Check what that
   requirement is for these entries and whether a character who has never
   gathered anything passes it.

6. **Walk for an hour.** The test is whether meeting a trainer feels like an
   event or an interruption, and no query answers that.

## Affected Files (anticipated)

- `src/lua-explore/` — travel.lua, movement.lua, periodic_events.lua in
  whatever form step 1 settles on
- a generator emitting the Gathering trainer table from the world database
- `docs/balance-updates.md` — the traveller interval, once it has been felt

## Related Issues

- **503** dynamic trainer spawning (completed) — normalised the class-trainer
  table and built `getTrainerForClass`; the same shape this issue follows
- **502** universal class trainers — the other trainer issue, and the one that
  found the travel system was switched off
- **501** custom merchant system — the vendor half of phase 5, deliberately
  not enabled here
- **148q** vanilla starting professions — if explore inherits it, characters
  arrive already knowing herbalism and mining and these trainers are redundant

## Open Questions

- **Named trainers or the two generic "World" ones?** Texture versus
  simplicity, and it also decides whether faction handling is needed at all.
- **Is 130 seconds right when the trainer is the only person alive?** In beta
  a traveller is one of ten kinds of encounter. Here it is the only one.
- **What happens once the player has learned everything both trainers teach?**
  The bag regenerates and the same two keep arriving with nothing to sell.
  Does the category switch off, or do they become someone to talk to rather
  than train with — which is 153e's territory?
- **Should the trainers themselves be naturalists?** 153e gives bots something
  to say about plants. A herbalism trainer is the one NPC in the world who
  would obviously know. Whether the voice belongs to the trainers, the bots,
  or both is worth deciding before either is built.
