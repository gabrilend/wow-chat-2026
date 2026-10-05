# 167 - Spirit Heals by Stamina

## Status
- Created: 2026-10-04
- Phase: 1
- Priority: Medium
- Patch: B049 (`patches/B049-spirit-heals-by-stamina.sh`), basic
- Related: 155k1 (stamina scaled to the threat: the other half of
  "players have too little health")

## Origin

Verbatim, 2026-10-04:

> can we add a patch that makes spirit restore hp5 equal to the amount of
> mana it would restore if the character wasn't casting?

## Second word, 2026-10-04

> Can we have warriors, rogues, and death knights gain the same rate as
> everyone else, and make that rate equal to about 1/100th of the amount
> of stamina (not hit points) they have? So 100 stamina means 1hp5 per
> spirit, right? so a tank with 300 stamina would get 3hp5 per spirit, so
> 300 spirit means 900hp per 5 seconds, right?

On "out of combat only, or in combat too?":

> in combat too. Interrupted by taking damage, and recovers at 50%, just
> like spirit does with mana

And for later:

> we'll probably want to add spirit to weapons and armor, but I'm not sure
> how to do that in a balanced way. Probably need to replace another
> attribute or divide it and use the other parts of the budget as spirit
>
> probably stamina tbh... should keep roughly the same amount of
> survivability? Maybe?

## Current Behavior

**Patch rewritten 2026-10-04 (B049, second form), not yet compiled; the
first form (health equal to spirit's out-of-casting mana, classes without
mana stock) was never built.** Before it, stock: out of combat only, a
character's health comes back every 2 seconds from spirit through the
server's health-per-spirit tables (by class and level; warriors and death
knights about 0.5 per spirit at 60, casters 0.04-0.13).

## Intended Behavior

Every class alike: spirit restores health at stamina / 100 per point of
spirit every 5 seconds, so health per 5 seconds = spirit x stamina / 100
(stamina the attribute, not hit points). A tank with 300 stamina and 300
spirit: 900 health per 5 seconds; a priest with 150 stamina and 300
spirit: 450. Each 2-second health tick gives 2/5 of that.

- **In combat too**, at the same rate.
- **Taking damage interrupts it**: for 5 seconds after the last damage
  taken, spirit heals at half rate (as mana from spirit drops while
  casting). Damage taken is any damage dealt to the player (`Unit::DealDamage`,
  after the server's own damage hooks).
- Unchanged: sitting adds a third; health-regeneration percentage effects
  multiply it (in this client a short list, Spell.dbc aura 88: the troll
  racial Regeneration, Blood Presence, a few potions and many monster
  debuffs that cut regeneration: Rabies, Cadaver Worms, Putrid Bile,
  Enfeeble, Aura of Suffering); the other sources of health regeneration
  add to it as before. Mana regeneration is untouched.

**Later (not this patch): spirit on gear.** Weapons and armour carry
little or no spirit today. Adding it means taking budget from another
stat, most likely stamina, keeping survivability about the same (open
question 2).

## Suggested Implementation Steps

1. (Done) B049, three files, insertion only. The half rate after damage is
   the twin of the server's own five-second rule for mana (owner,
   2026-10-04: "how do we handle it for spirit? Can't we use the same
   system, just abstracted a little?"): every unit keeps when it last
   spent mana (`m_lastManaUse`, `SetLastManaUse`), and regeneration asks
   `IsUnderLastManaUseEffect` (under 5 seconds ago?). Beside those three,
   in the same shape:
   - `Unit.h`: `SetLastHurt`, `IsUnderLastHurtEffect`, `m_lastHurt`
     (milliseconds of game time, 0 = never).
   - `Unit.cpp`: damage dealt to any unit sets it; the check is defined
     beside the mana one.
   - `Player.cpp`: the health-per-spirit function returns spirit x stamina
     / 100 x 2/5, halved while `IsUnderLastHurtEffect`; the 2-second tick
     runs in combat too for a player the stock check would skip, and adds
     the spirit part in combat.
   `Unit.h` is included almost everywhere (as `m_lastManaUse` is), so a
   compile after this patch rebuilds most of the server; any new per-unit
   time would. Checked 2026-10-04 on clean copies: applies once, both
   .cpp files compile with the build's flags (without its precompiled
   header, which would hide the patched header), reverts byte-identical.
2. `scripts/test-source-patches basic` once the source tree is clean.
3. In game: the tank example's 900 per 5 seconds standing still out of
   combat; half for 5 seconds after a hit; still healing mid-fight.

## Open Questions

1. (Answered 2026-10-04) Warriors, rogues, death knights: the same rate as
   everyone; and in combat too, halved after damage.
2. Spirit on gear: take its budget from stamina (keeping survivability
   about the same), and at what exchange (spirit's healing is worth more
   on a high-stamina character)?
3. (Answered 2026-10-04) "no the mana regeneration should remain
   unchanged": mana from spirit is untouched (B049 never changes it); the
   stamina rule is everyone's health from spirit.
