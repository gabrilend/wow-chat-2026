# 155k2 - Spirit on Gear

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155k (the gear ladder: item rescales on basic)
- Blocked by: 167 (spirit heals by stamina: what makes spirit worth having
  on every character)
- Priority: Medium

## Origin

Verbatim, 2026-10-04:

> we'll probably want to add spirit to weapons and armor, but I'm not sure
> how to do that in a balanced way. Probably need to replace another
> attribute or divide it and use the other parts of the budget as spirit
>
> probably stamina tbh... should keep roughly the same amount of
> survivability? Maybe?

> How about roughly 1/5th of items have their stamina cost 100% replaced
> for spirit. Only if they don't have any spirit already on that item, and
> also only if there's at least some stamina on that item. Another 1/5th
> can have the stamina amount reduced by half, and made into spirit. We
> should have roughly the same amount from each armor category (cloth,
> leather, mail, plate) normalized for number of items in that category.
> Also, we shouldn't touch any gear that requires a certain class or
> faction. Also we shouldn't touch PvP gear, there's enough healing there
> already... But spirit still takes effect in PvP of course, just, not
> from PvP gear.

## Current Behavior

Not built. Weapons and armour carry spirit mostly on caster items; since
167 spirit heals every class by stamina, so it is now worth having on any
character.

## Intended Behavior

**Narrowed 2026-10-25** (the owner): "we shouldn't touch tier gear, btw.
Also, we shouldn't touch cloth gear or mail gear. Just leather and
plate." So only leather and plate armour change (cloth and mail never,
nor any piece of a tier set); the fifths are drawn within leather and
within plate. Mail armour too when it carries no intellect, mana every
5 seconds or spell power; rings, necklaces and cloaks change; weapons do
not (open question 4, answered).

Some gear trades stamina for spirit:

- **Which items may change**: weapons, armour, rings, necklaces and cloaks
  ("no to trinkets. yes to the others") that carry some stamina and no
  spirit; not restricted to a class or a faction; not PvP gear (honor,
  arena and battleground rewards, and world PvP rewards such as Halaa's
  and Hellfire's towers, which need a faction's standing anyway).
- **Two fifths change**, chosen at random but fixed (a seeded draw by item
  id, so a rebuild picks the same items):
  - one fifth: all of the item's stamina becomes spirit;
  - another fifth: half its stamina becomes spirit, half stays.
- **Even across armour types**: the fifths are drawn within each armour
  kind (cloth, leather, mail, plate) separately, so each kind gets the
  same share of changed items whatever its count; weapons as their own
  group.
- **The exchange** (owner, 2026-10-04): "less about budget, more about
  combat utility ... Do you help the healer's sustain (spirit) or
  throughput (stamina)? If they have to cast powerful, expensive spells to
  keep up, then spirit can be better. But if you're taking so much damage
  they can't get the slower, more efficient spells off, then stamina might
  be better. It depends on the healer, and the character. Trolls usually
  will want spirit, same for blood death knights :)" So no fixed budget
  rate: the item offers the choice between the two kinds of survival, and
  which is better is the wearer's (open question 1: the points given).
- Originals saved; an exact revert, as 155k's rescale.

## Suggested Implementation Steps

1. A generator: the eligible items by group, the seeded draw, the new
   stat rows, written as an install step's SQL (with 155k's save-and-
   revert pattern), after 155k's rescale.
2. The RAM test: apply, revert, checksum.
3. A page: how many items changed per kind and per level, spirit and
   stamina before and after.

## Open Questions

1. (Answered 2026-10-23, in 167: one for one, to playtest: "for
   preliminary results let's try weighting stamina and spirit the same.")
   The points: one stamina becomes one spirit (owner, 2026-10-04: "I
   dunno probably"; taken as the working rule, to be looked at again
   once it is seen in game).
   (Owner, 2026-10-04: "I think it's stamina * spirit / 100?", the healing
   rule of 167. That is what spirit does once on the item; the question
   here is how many spirit points an item gets for the stamina it gives up.
   Proposed: one for one, so 20 stamina becomes 20 spirit.)
   The arithmetic (2026-10-04, worked through with the owner): one
   stamina is about 10 health, so the rule heals spirit / 10 percent of
   maximum health every 5 seconds whatever the stamina (stamina sizes the
   pool and the healing alike): 100 spirit, 10% per 5 s, empty to full in
   50 s; 300 spirit, about 17 s; double at half rate after damage. A 1:1
   swap of 20 stamina for 20 spirit on a 5,000-health character gives up
   200 health once and gains 2% (100 health) every 5 seconds: spirit has
   paid it back after about 10 seconds of healing at full rate, 20 at half.
   Longer fights favour the spirit, bursts the stamina.
2. (Answered 2026-10-04) Rings, necklaces and cloaks in; trinkets out.
4. (Answered 2026-10-25) "no on weapons, yes on rings, necklaces, and
   cloaks. Also, we can do mail armor if it doesn't have int or mp5 or
   spellpower on it." So: leather and plate armour, mail armour with no
   intellect, mana every 5 seconds or spell power, and rings, necklaces
   and cloaks; never weapons, cloth, trinkets or tier pieces.
   **Weapons, rings, necklaces and cloaks**: since 2026-10-25 only
   leather and plate armour change. Do these (no armour kind of their
   own) still change, or nothing but leather and plate armour?
3. (Answered 2026-10-04) World PvP rewards are out ("yes, because requires
   faction, right?": they need a faction's standing, so the faction rule
   already leaves them out).
