# How a buddy is geared, trained and kept: the spec

*Rules and patterns, not item lists (the owner, 2026-10-27: "can we WRITE a
spec for how they should be geared at various stages? Rules and patterns,
not specifics"). The specifics live in the gearsets
(`src/lua-basic/data/gearsets/`), the gem tiers (`buddies_gems.cpp`) and the
PvP vendors' lists. `scripts/check-buddies` tests every buddy on the server
against the rules marked **[checked]**; the others are kept by the code that
dresses a buddy (named with each rule).*

## When a buddy is dressed

A buddy is dressed whole, by the same steps, at each of these moments, and
not otherwise (in play it finds, wins and buys its gear as a player does):

| Moment | By |
|---|---|
| Made by Sargobras | `BuddyMakeCharacter` (`buddies_create.cpp`) |
| Made again at its owner's level (its slot came back) | `Remake` (`buddies_stage.cpp`) |
| Its level moved by more than one at once | `LevelJumped` (`buddies_stage.cpp`) |
| Its class changed (`scripts/change-character-class`) | `Reclassed`, at its next login (stage 6) |
| A game master's `.buddy kit` | `HandleKit` (`buddies_kit.cpp`) |

And, to bring a buddy up to this spec without taking off what it earned
(lessons, skills, the kit only in empty slots, tools, jewellery when a slot
of it is empty, gems): `.buddy spec [name]` in the world, or stage 7 in its
roster row for its next login (`BuddyBringToSpec`). After a change to the
spec, every buddy is set to 7 once.

## Who it is

1. **Its class is its roster's class** (`buddy_roster.class` = the
   character's class). **[checked]**
2. **It has a talent plan** (1-10: thirds of its points per tree, the same
   ten shapes for every class) **and a role its class can take**: a tank
   only for warriors, paladins, druids and death knights; a healer only for
   paladins, priests, shamans and druids. **[checked]**
3. **It is never above its owner's level while with its owner** (stage 0):
   a higher one waits (1), is recorded first (4), is set aside (5, a death
   knight owner's, 718), or is made again (3). Stages 6 (reclassed) and 7
   (to spec) are dressings due at its next login. **[checked]**

## What it knows

4. **Every lesson of its class up to its level** (trainer lessons and
   quest spells, free). Checked by `scripts/teach-character-lessons --dry-run`
   with the server stopped.
5. **Every weapon skill it has, and defence, at the maximum for its level**
   (the server's `.levelup` step, at each dressing moment). In play they
   grow by use, as a player's do. **[checked]**
6. **The weapon kind its kit gives it** (learned before the kit goes on).

## What it wears

7. **The white kit of its level tier, chosen by its talent plan**: the tier
   at or below its level (`buddy-white-1`, `-10`, ... `-60`), each slot the
   tier fills filled, the best armour type its class wears. Shirt and
   tabard untouched. **[checked: no empty armour slot]**
8. **A weapon it can use in its main hand**, never a fishing pole or a
   profession tool, except while it fishes (`buddies_arms.cpp` puts weapons
   away in town; that is the place, not the kit). **[checked]**
9. **From level 30, at its making only: its weapon's permanent enchant**,
   one of four melee procs at random (621).
10. **From level 18: player-versus-player jewellery**: the best necklace,
    two rings and two trinkets of its level that its side may wear
    (Alliance-only items never on the Horde, and back), bought with honor or
    arena points. The second ring and trinket is another item than the
    first, from another battleground where there is one, and only when it
    scores at least three quarters of the first's lower-level copy (else that
    copy). **[checked: present, its side's, not the same item on both fingers]**
11. **Every socket gemmed**, by its plan, from its gem tier (by item level),
    plain cut gems only: no meta gems, nothing unique, no test or
    placeholder items. **[checked]**
12. **Its class's tools**: a rogue's poisons from 20 (Instant and Deadly, a
    stack each), a hunter's ammunition, a shaman's totems. **[checked: a
    rogue's poisons]**
13. **Bags: as many bag slots as its owner had when it was made**; after
    that it finds its own. **[reported, not judged]**

## Not yet in the spec (asked, being built)

- A death knight buddy's kit: the Acherus Knight's green gear, unless its
  owner played the story, then the quest rewards its owner earned (a cloak
  and a weapon chosen at random among them). Issue 718 family.
- Making room for an upgrade when its bags are full; celebrating it (617j4).
