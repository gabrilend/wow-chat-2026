# 617a4a - Dressed from the Valley's Vendors

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617a4 (the buddy starting kit)
- Related: 155d1 (another valley, please: the owner's valley changed by
  Sargobras), 155d (rotating starting valleys), the gearsets (617r: the
  white kit by tier), `docs/buddy-gear-spec.md` (rule 7)
- Priority: Medium
- State: plan only; nothing built

## Origin

The owner, 2026-10-27:

> when you switch starting zones by talking to Sargobras, your buddy (if you
> have one) should switch gear to the equipment sold by the vendors in that
> area. notice glowsticks set of gear? that set, if they were transferring
> to Eversong Woods. They should also use that set when they are created I
> think.

Glowsticks (a level-4 troll shaman in Eversong Woods), 2026-10-27, wore
what Sunstrider Isle's and Eversong's vendors sell: the Sun Cured set (vest,
belt, pants, boots, bracers, gloves), the Daylight Cloak and the Mana
Gathering Staff. Her buddy Jecunsek wore the kit's mix of grey and white.

## Current Behavior

A buddy made at level 1 wears its race and class's starting outfit (since
2026-10-27, `GiveGear` in `buddies_kit.cpp`); above level 1 the white kit
of its level tier (`buddy-white-1`, `-10`, ...), chosen by its talent plan,
the same everywhere. A change of valley by Sargobras moves the owner and
its buddies, and changes nobody's gear.

**The valleys' vendors, measured 2026-10-27** (`scripts/generate-valley-vendor-report`,
`docs/reports/valley-vendor-gear.md`; items usable at level 1 only, the
owner: "we should only use the items usable at level 1 of course"): in
every zone the vendors fill chest to hands and the main hand; none sells a
head, shoulder or back item at level 1; ranged weapons only for warriors,
hunters and rogues. Mulgore sold no cloth (tauren could not be cloth
classes); install step E074 (written 2026-10-27, SQL tried in a rolled-back
transaction, not yet installed) gives Varia Hardhide, Camp Narache's leather
merchant, the level-1 Thin Cloth set and the title "Cloth & Leather
Merchant" (the owner: "let's change her to say "cloth and leather merchant"
instead"). Searched by valley (each valley's own area, every piece of it), not by
zone: a first run by zone missed Sunstrider Isle, an area of its own, whose
Jainthess Thelryn (15291, Cloth & Leather Merchant) and Raelis Dawnstar
(15289, Weaponsmith) sell the level-1 Sun Cured set and Mana Gathering Staff
Glowsticks wore (the owner: "how did glowsticks find their gear if they
didn't buy it from a vendor? Use your head. Find the right vendors."); the
Eversong Woods vendors of that first run sell at level 5. Each valley has
four or five such vendors (the report). The client's cache: install step C025's cache version now follows
the SQL the profile's patches carry in their own folders (it had missed it
since 189e), so E074's rename reaches clients at their next login.

## Intended Behavior

1. **The valley's own gear**: a buddy made in a starting valley, or whose
   owner moves to another valley by Sargobras, wears the gear the valley's
   and its zone's vendors sell, for each slot such a vendor fills: the
   best by its talent plan that its class wears and its level allows.
2. **The rest as before**: slots no vendor there fills keep the kit's (or
   the starting outfit's) items; jewellery, gems and tools as the spec says.
3. **On a valley change**: what it wore in those slots is left behind in the
   old valley (destroyed; the owner, 2026-10-27: "the old pieces should be
   left behind, in the old valley, of course. What use would they have in
   the new starting zone?").
4. **Starting gear only**: it is what a buddy starts with; it equips better
   as it goes, as a player does (the owner: "it's just their starting gear.
   They will equip better as they go").
5. **Weapons from the vendors too** (the owner: "vendor weapons").

## Suggested Implementation Steps

1. Which vendors belong to each starting valley: named by hand, per valley
   (the owner, 2026-10-27: "we may have to specify the vendors manually on a
   per-valley basis"), in one data file; a first list of candidates (the
   vendors spawned in each valley's zone selling armour or weapons) read
   from the world database for the owner to confirm.
2. A gearset per valley made from those vendors' wares by a generator
   (`scripts/generate-...`, as the white tiers are), keyed by class and
   plan: the best item for each slot the vendors fill.
3. A report per class and valley of which slots the valley's vendors fill
   and which fall back to the kit or the starting outfit (the owner: "I will
   need a report on these for each class").
4. The kit, at a buddy's making in a valley, and Sargobras's valley change,
   use the valley's gearset for the slots it fills.
5. `scripts/check-buddies`: a buddy in a starting zone wears that zone's
   vendor gear where the zone sells it.

## Open Questions

1. (Answered 2026-10-27, Intended 4) Starting gear only.
2. (Answered 2026-10-27, Intended 5) Weapons too.
3. The vendors of each valley: the candidate list to be confirmed.

