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

Worked example (2026-10-23), a level-60 warrior: base 1689 health, 110
stamina and 45 spirit from the class (`player_class_stats`), plus 190
stamina from gear (300 in all); health = base + 20 + 10 x (stamina - 20).
Gear stamina moved to spirit one for one, at the divisor of 200:

| moved | stamina | spirit | health | heal / 5 s | refill | refill while hit |
|------:|--------:|-------:|-------:|-----------:|-------:|-----------------:|
|     0 |     300 |     45 |   4509 |       67.5 |  334 s |            668 s |
|    50 |     250 |     95 |   4009 |      118.8 |  169 s |            338 s |
|   100 |     200 |    145 |   3509 |      145.0 |  121 s |            242 s |
|   150 |     150 |    195 |   3009 |      146.3 |  103 s |            206 s |
|   190 |     110 |    235 |   2609 |      129.3 |  101 s |            202 s |

With the sum fixed, healing peaks where stamina and spirit are about
equal (their product is largest there), so one for one never reaches the
300-and-300 example above. The exchange rate sets how much health a spirit
build gives up; the divisor (100) sets how fast everyone heals. The owner,
on the in-combat worry: "it's half effect in combat. For another, their
stats will go down because we pull from stamina to provide spirit. We're
just trying to figure out the correct ratio."

**The divisor back to 100, 2026-10-25**, after the boss numbers below ("I want spirit to be useful in combat"). Before that, **the divisor doubled, 2026-10-23** (from 100 to 200, in B049 and
`docs/balance-updates.md`): at 100 a spirit build refilled in about a
minute standing. The owner: "we should double the divisor so the numbers
are doubled. A full refill should take ~2 minutes I think. That's much
longer than the 30 seconds it takes to eat / drink." The owner's own
example (300 stamina and 300 spirit, 900 per 5 seconds) is 450 now, and is
out of reach when spirit is bought with stamina (the table).

**In a raid boss fight, and in Outland's dungeons** (2026-10-23/24). The
owner: "I want spirit to be useful in combat. I also want it to be useful
for people who aren't tanks ... I mostly want to defeat those "always
correct choices" which aren't really choices at all" (in WotLK tanks gemmed
only stamina), and worried that basic's raised Outland dungeon bosses
"will essentially one-shot our tanks". `scripts/tank-damage-taken
[--divisor N] [--crushing basic|stock] ...` works it out from the world
database with the server's own formulas (melee only; spells, blocks and
healers left out) for the level-60 raid bosses, both Kazzaks, and every
boss of the sixteen Outland dungeons at basic's levels (E024), Kael'thas
in Magisters' Terrace included. What it showed, for a 4509-health,
10,000-armour tank:

- **No dungeon boss one-shots the tank.** The biggest single hits are
  11% to 82% of its health (Exarch Maladaar the worst, 3707); with no
  healing it lasts 4 to 26 seconds. Basic's crushing rule (B031: none
  until 8 levels up, full at 12) is what keeps it there: from level 71
  every swing that lands crushes, and defence above 300 cannot help at 60.
- **Both Kazzaks do** (level 73): Lord Kazzak's hits are 97% of the tank's
  health, Doom Lord Kazzak's 315%. World bosses fight as 3 levels above
  their target, so neither crushes; the size is their level-73 damage.
  They are raids (155j).
- **Spirit's share of the damage, while being hit:** at divisor 100 the
  best build (200 stamina, 145 spirit) heals 29 a second, 2% to 17% of a
  boss's melee; at 200, half that.

**Is spirit a choice?** With the two stats sharing one budget, the best
split for a fight of T seconds (health plus what spirit heals over the
fight, at rate r: 1/2 while hit, 1 otherwise) is stamina - spirit = 50 x
divisor / (r x T). For the warrior above (345 of the two together):

| fight  | divisor 100, hit | divisor 100, not hit | divisor 200, hit | divisor 200, not hit |
|-------:|-----------------:|---------------------:|-----------------:|---------------------:|
|   60 s |       256 / 89   |           214 / 131  |       300 / 45   |           256 / 89   |
|  120 s |       214 / 131  |           193 / 152  |       256 / 89   |           214 / 131  |
|  180 s |       200 / 145  |           186 / 159  |       228 / 117  |           200 / 145  |
|  300 s |       189 / 156  |           181 / 164  |       206 / 139  |           189 / 156  |

(stamina / spirit.) So the answer depends on the fight's length and on
whether the boss is hitting you: no single build is always right, which
is the owner's aim. The table ignores the burst limit (health must outlast
the biggest run of hits), which pulls tanks toward stamina against bosses
like Maladaar.

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
2. (Answered 2026-10-23, preliminary, to playtest) "for preliminary results let's try weighting stamina and spirit the same." So when spirit is put on gear, each point of it costs one point of stamina from the item's budget. The owner also checked the arithmetic: spirit x stamina / 100 per 5 seconds is spirit x stamina / 500 per second; since one stamina is about 10 health (the first 20 give 1 each), that is about spirit x health / 1000 per 5 seconds; and it runs in combat, at half rate for 5 seconds after each hit. "I think we will need to playtest this." Spirit on gear: take its budget from stamina (keeping survivability
   about the same), and at what exchange (spirit's healing is worth more
   on a high-stamina character)?
3. (Answered 2026-10-04) "no the mana regeneration should remain
   unchanged": mana from spirit is untouched (B049 never changes it); the
   stamina rule is everyone's health from spirit.

4. (Answered 2026-10-25: 100, "yes I think so") **Divisor 100 or 200**, now that the owner wants spirit useful in
   combat and for non-tanks: 200 (in B049 since 2026-10-23) makes a full
   refill take about two minutes standing; 100 doubles spirit's share in
   fights (2-17% of a boss's melee while hit) and pulls the best builds
   toward spirit (the table above).