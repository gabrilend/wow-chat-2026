# 617e4b - Weapons by Place: Bare in Town, Sheathed in the Wilds, Drawn in Danger

## Status
- Created: 2026-10-15
- Phase: 6
- Parent: 617e4 (town visits)
- Related: 617a4 (the starting kit: the weapons), 617k (the fishing pole),
  622 (the buddy's weapon record)
- Priority: Medium
- State: built 2026-10-15; syntax-checked, not yet rebuilt, installed or run

## Origin

Verbatim, 2026-10-15, on a buddy holding its fishing pole in a fight:

> when in town, they shouldn't carry any weapons at all. While in the
> wilds, they should bear their sword on their hip or back. When in
> danger, they should bear it in hand. in town or at peace, they
> shouldn't bear the fishing pole - only when they are fishing, or when
> it's on their todo list and they would otherwise bear nothing.

Asked when a buddy is "in danger" (2026-10-15, verbatim): "when
they're questing in a hostile place, or in a dungeon, or in a
battleground or arena." Asked whether to build it: "seems clear enough.
Can we build it?"

## Current Behavior

**Changed the same day, by the owner's answers; syntax-checked, not yet
rebuilt or run.** Verbatim: "we don't have to remember. They should equip
their best one when they're going off adventuring." / "they never sell
their *best* weapon, which is what they should remember and re-calculate
anytime they get a new one. If there's two that are good, they can
exchange them in different situations. And they shouldn't be sold,
either." / the change of carrying should happen "anytime we enter an
event or situation or environment that demands it." / danger is
"specifically when they are questing" (617e4c) / on bows, guns and wands
going into the bags in town too: "good."
- No table: leaving town (or a fight) puts on the best weapons it
  carries, worked out then by the bot module's stat weights for it: main
  hand, off hand (unless a two-hander), ranged. The best and runner-up of
  each slot are never sold.
- A buddy's situation (town, open, danger; fighting; fishing) is watched
  and the weapons change only when it changes: entering or leaving town,
  a fight starting or ending, the fishing starting or ending, logging in.
- Danger is only an instanced map for now (dungeon, raid, battleground,
  arena); the other faction's land no longer counts. Questing, roads and
  fishing flocks wait on 617e4c.
- The `buddy_stowed_weapon` table and its startup check are gone.

**First version, 2026-10-15 (replaced as above)**
(`patches/B036-mod-buddies/mod-buddies/src/buddies_arms.cpp`): every two seconds each
online buddy is looked at.
- In a town, out of a fight: main hand, off hand and ranged weapon go
  into its bags, each written into the characters table
  `buddy_stowed_weapon` (install step E042's file,
  `sql/basic/db_characters.src/04-buddy-roster.apply.sql`; the module
  stays off at startup without it). The pole stays in hand while the town
  visit is fishing, and goes into the bags otherwise. Bags too full: that
  weapon stays worn, logged once per town stay. The town's selling keeps
  the put-away weapons.
- Anywhere else, or a fight starting anywhere (the combat hook, at once):
  the written-down weapons are worn again and their rows removed; drawn
  (the melee sheath state) in danger or a fight, sheathed in the wilds.
  Danger: an instanced map (dungeon, raid, battleground, arena) or a zone
  whose team in AreaTable.dbc is the other faction; contested zones are
  the wilds. "Questing" is not looked at: being in the other faction's
  land is enough.
- A pole in the main hand outside town with nothing written down: the
  best weapon in its bags (the earlier safety net, moved here).
- Found while building: the server's "is in a bag" test is false for the
  backpack, so the fishing visit never put back a weapon that sat in the
  backpack (Mozonn's hammer). The fishing visit and this pass now ask
  "not worn" instead.

Before:
- A buddy wears its weapons everywhere; whether they are drawn or
  sheathed is left to the bot module and the game's defaults.
- The fishing pole goes into its hand for a town fishing visit and back
  to its bags when the visit ends in town (617e4). Since 2026-10-15
  (`buddies_town.cpp`, "the pole in a fight"), a pole still in hand at
  login or when a fight starts is swapped for the best weapon in its
  bags, so the pole never fights.

## Intended Behavior

Three places, three ways of carrying:

| Where | Weapons | The fishing pole |
|---|---|---|
| In a town (the town areas of 617e4, its buildings too) | none worn: main hand, off hand and ranged go into the bags | in hand only while fishing, or walking to fish, since its hands are otherwise empty |
| In the wilds, at peace | worn and sheathed (on the hip or back) | in the bags |
| In danger (in combat, or a hostile closing in) | worn and drawn | in the bags |

Entering a town takes the weapons off; leaving it puts them back on
(sheathed). A fight in town (a raid on a capital, a duel) puts them on and
draws them at once.

## Suggested Implementation Steps

1. Answer the open questions.
2. A per-buddy note of what it wore in each hand slot (item guids),
   stored in the characters database rather than memory (memory is what
   lost Mozonn's hammer), written as the weapons come off.
3. Entering town (the town step's first turn in a town): each weapon
   moved to the bags through the client's own swap-to-bags request, so
   every server rule applies; full bags leave that weapon worn and say
   so.
4. Leaving town, or a fight starting anywhere: the noted weapons put
   back, then drawn (in a fight) or sheathed (at peace), by the sheath
   state the server sends for a player.
5. The pole: in hand when a fishing visit begins in town (its hands are
   empty there), back in the bags when it ends; the login and
   fight-start check of 2026-10-15 stays as the safety net.
6. In game: walk a buddy into Orgrimmar and out to the Barrens; start a
   fight at the gate.

## Open Questions

- Later (owner, 2026-10-15): "eventually we will implement piercing,
  blunt, and slashing damage. Then we will have more reasons to wear more
  than one type of weapon." The best-and-runner-up rule is where a buddy
  would carry one of each kind and change by the foe.

1. (Answered 2026-10-15: questing in a hostile place, a dungeon, a
   battleground or an arena.)
2. Ranged weapons and wands: taken off in town too, as built. Right?
3. Should the owner's own weapons follow the same rule (a Lua script for
   players), or only buddies?
- (Answered 2026-10-23) **Buddies only, and ranged only for those who fight
  with it:** "just buddies, and yes to ranged weapons if they primarily
  use their ranged weapon as their main weapon. Right now that's just
  hunters." So the owner's own weapons are never touched; in town a
  buddy's main and off hand always go into its bags, and its ranged weapon
  does too only when ranged is its main weapon (hunters today); a
  warrior's bow or a priest's wand stays worn. (Questions 2 and 3 above.)
