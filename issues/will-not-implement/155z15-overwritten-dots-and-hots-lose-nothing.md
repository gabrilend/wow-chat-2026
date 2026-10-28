# 155z15 - Overwritten DoTs and HoTs Lose Nothing

## Status
- Created: 2026-10-26
- Phase: 1
- Parent: 155 (the basic profile)
- Related: 155z14 (crowd control without diminishing returns: another of
  basic's combat rules), the server's periodic auras (`AuraEffect`,
  `Aura::RefreshDuration`, `Aura::TryRefreshStackOrCreate`)
- Priority: Medium
- State: will not implement (2026-10-27), for now: the owner, "can you
  mark this as "will-not-implement" with the caveat that we could improve
  the design and think through it better first? We haven't gotten the
  datapath flow correctly mapped yet." Revisit once the periodic auras'
  data path (cast, overwrite, tick, refund) is mapped in docs/datapaths/.

## Origin

The owner, 2026-10-26:

> can we add a patch to change how DoTs and HoTs tick? When they are
> overwritten, they should calculate how much of a tick is left over. This
> only applies for the last tick - otherwise, if there's more, it's treated
> as 100% of one tick and no more. Anyway, what we do is we calculate the
> proportional damage or healing that would be lost, and then we apply that
> as a buff to the first tick of the next one. Any extra ticks beyond the
> last one get returned to the player as proportional mana. So casting a
> heal or debuff damage is free, no matter when you do it, it just costs
> the action economy.

## Current Behavior

Stock 3.3.5: casting a damage-over-time or heal-over-time spell on a
target that still has the caster's own copy replaces it. What was left of
the old one (the part of the current tick already elapsed, and every tick
not yet done) is lost, and its mana with it, so recasting early wastes
both.

## Intended Behavior

When a caster's periodic damage or healing aura is overwritten by the
caster's own new cast of it (the same spell, any rank: an open question):

1. **The tick under way**: the part of it not yet applied but whose
   duration has been running (the owner, 2026-10-27: "the part that has
   not yet been applied, but has been ticking duration, is added to the
   next tick"), in proportion to the time since the last tick over the
   tick's length, is added to the new aura's first tick, when that tick
   happens. At most one tick is carried this way.
2. **The ticks not yet begun** (beyond the one under way): their share of
   the old cast's mana cost is given back to the caster:
   mana back = cost × (whole ticks left) / (ticks in all).
3. So recasting loses neither damage nor mana: it costs only the cast's
   time (the owner: "it just costs the action economy").

Example: a 5-tick DoT costing 100 mana, overwritten 2.5 ticks in: half of
tick 3 is added to the new aura's first tick; ticks 4 and 5 are two of
five, so 40 mana comes back.

## Suggested Implementation Steps

1. Find where the server replaces a caster's periodic aura with a new
   cast (`Aura::TryRefreshStackOrCreate`, `Unit::_TryStackingOrRefreshingExistingAura`)
   and where the periodic amount is computed per tick
   (`AuraEffect::HandlePeriodicDamageAurasTick`, `...HealAurasTick`).
2. A pure function for the carry-over: given the old aura's tick length,
   time since its last tick, ticks left, per-tick amount, and the spell's
   cost, it returns the bonus for the new first tick and the mana to give
   back. A test of it (the example above, a tick just begun, a tick almost
   done, the last tick).
3. A source patch (basic): on overwrite, compute the carry-over, store the
   bonus on the new aura's effect for its first tick only, give the mana
   back; marker comments, a clean unpatch.
4. Seen in game: a DoT recast early, its next first tick bigger by the
   carried share, the mana bar refunded.

## Open Questions

1. **Which overwrites**: only the caster's own copy of the same spell? Any
   rank of it (a lower rank recast over a higher)? Another caster's copy
   is not overwritten in 3.3.5 (each caster keeps their own), so it does
   not arise.
2. **The carried tick and bonuses**: is the carried amount the old tick's
   final number (after the caster's bonuses and the target's
   reductions), or the base amount, letting the new cast's bonuses apply?
3. **Spells that cost something other than mana** (rage, energy, runic
   power: a rogue's Rupture, a warrior's Rend): give back that resource
   in the same share, or mana only?
4. **Channelled spells** (Drain Life, Mind Flay) and spells whose ticks
   grow (Agony's damage rises each tick): included, and with which tick's
   amount?
