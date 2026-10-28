# 718h - The Acherus Knight's Green, by Default

## Status
- Created: 2026-10-27
- Phase: 7
- Parent: 718 (the death knight's sacrifice, Acherus open)
- Related: `src/lua-basic/death-knight-buddy-gear.lua` (a death knight
  owner's buddies dressed from the story's rewards, 2026-10-12),
  `docs/buddy-gear-spec.md` (the spec's open item), 617r (gearsets)
- Priority: Medium
- State: plan only; nothing built

## Origin

The owner, 2026-10-27:

> also the death knight buddy-kits should have the Acherus Knight green
> gear equipped. Unless the player plays the story, then all future
> buddy-bots should have any gear upgrades that are from the quests that the
> player completed. For the cloaks and weapons, select one randomly.

## Current Behavior

`death-knight-buddy-gear.lua` dresses a death knight owner's buddies, ten
seconds after each appears and after each story reward: every item of every
story quest the owner was rewarded (a later item for a place replacing an
earlier one; the choice quests, three cloaks and two great weapons, chosen
at random once per buddy), and its weapon (the Runed Soulblade for the 55
and 57 buddies; for 59 and 60 the final quest's great weapon once earned,
else a random green two-hander). An owner who skipped the story (ledger
"skipped") has its quests rewarded but none of their gear, so its buddies
get only the weapon rule, and otherwise wear the buddy module's white kit.
A death knight buddy of an owner who is not a death knight has no rule at
all (the white kit).

## Intended Behavior

1. **Every death knight buddy starts in the Acherus Knight's green gear**
   (the set the story's quests give, the full set at the level the buddy
   is made), whoever its owner is and whether the owner skipped.
2. **An owner who plays the story**: each story reward the owner has been
   given that is better for a place than the Acherus Knight's green there
   replaces it, for every future buddy and the ones already made, as now.
3. **Cloaks and weapons**: chosen at random among the story's choices, once
   per buddy, kept the same for that buddy (as now).
4. **Its sockets gemmed and its jewellery** as every buddy's (the spec).

## Suggested Implementation Steps

1. List the Acherus Knight's green items by slot (the story quests' reward
   items, read from the world database's quest rewards), the set for a
   buddy made at 55-60.
2. In `death-knight-buddy-gear.lua`: the default record is that set; the
   owner's rewards override it place by place; a skipper's buddies and a
   non-death-knight owner's death knight buddies get the default.
3. `scripts/test-dk-buddy-gear` extended: a skipper's buddy wears the set;
   a story-player's buddy wears its owner's rewards over it; the random
   choices stay fixed per buddy.
4. `scripts/check-buddies`: a death knight buddy's armour slots hold the
   set or better.

## Open Questions

1. "The Acherus Knight green gear": the story's own reward set (the
   Acherus Knight's helm, shoulders...), or a named set of that colour
   (there are several)? The story's rewards come in steps through the quests:
   at a buddy's making, all of them at once?
2. A non-death-knight owner's death knight buddy: does it get the set too,
   or the white kit like the others?
