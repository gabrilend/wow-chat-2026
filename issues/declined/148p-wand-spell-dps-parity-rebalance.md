# 148p - Wand DPS at ~100% of Spell DPS (Vanilla Profile)

> **DECLINED 2026-07-15.** The item-wide wand→spell DPS parity rebalance
> will not ship. It is a large cross-cutting pass over every wand in
> `item_template` in service of a niche auto-attack-only caster build,
> and the 148h kit already ships its starter wands at a 20-DPS
> placeholder, which is acceptable for launch. Kept on disk as a record;
> revisit only if build-diversity playtesting shows caster auto-attack
> parity is genuinely wanted.

## Status
- **Declined: 2026-07-15** (kit's 20-DPS placeholder wands stand)
- Created: 2026-06-12
- Phase: 1 (Foundation — gameplay knob)
- Parent: 148 (vanilla profile)
- Related: 148h (the kit redesign that sets baseline wand DPS to 20)
- Priority: Low (deferred — not blocking kit ship, addresses long-term
  build-diversity design rather than a broken feature)

## Problem

Vanilla WoW's wand damage was tuned around the principle that wands
are a tertiary damage source: a caster's spells do the heavy lifting,
the wand fires off during the time the caster is waiting for mana to
regenerate or for a cast bar to refresh, and the wand contributes
roughly 25-30% of the total damage output. At level 20, a stock wand
sits at ~17-18 DPS while spells like Frostbolt rank 4, Smite rank 4,
or Shadow Bolt rank 3 sit at 30-40 sustained DPS.

This server's design pillar is "the player should be able to pick
how they play, and if they want to auto-attack their way to greatness
that's fine." The vanilla wand-tuning explicitly punishes the
auto-attack-only build for casters: a priest who wants to wand-shoot
through the level-20 content does about 1/3 the damage of one who
casts Smite. There's no path to roleplaying a "wandering wand-mage"
at functional parity.

The fix is a damage-scaling pass on every wand in the item DB so a
caster wanding at full attack-speed deals approximately the same DPS
as the same caster casting their highest available rank spell at
full cast-speed. That parity lets players choose between cast-heavy
and auto-attack-heavy builds with no mechanical penalty for either.

## Why deferred

Three concerns push this out of the 148h kit work:

1. **Scope**. The kit only assigns starting wands. A proper rebalance
   touches every wand in the item DB — hundreds of entries across
   the level range. That's its own concentrated effort, not a
   side-tweak of the kit work.

2. **Gear-scaling interaction**. Spell damage at level 20+ scales
   with `+Spell Damage` gear stats; wand damage scales with wand
   speed and base wand damage, plus a separate (smaller) `+Spell
   Damage` coefficient. Achieving 100% parity *at level 20* with
   base gear is one design problem; achieving it across the level
   range and with stat gear is a related but distinct one. This
   issue scopes to level 20 base-gear parity first; the level-curve
   work follows.

3. **Talent contribution unaccounted for**. Caster talents at L20
   (Imp. Fireball, Imp. Wand Specialization for priests, etc.)
   shift the parity target. The kit grants enough talent points
   to fill one tree (per 148m), so the wand-parity target should
   account for "wanding a caster who put zero points in cast-spell
   talents" vs "wanding a caster who took Imp. Wand Specialization."

The kit ships with wands at 20 DPS — a modest bump over vanilla's
17-18, signaling intent without committing to the full parity rule.
This issue tracks the real fix.

## Reference data: spell DPS at level 20

Sustained DPS at the highest rank learnable at level 20 (or one rank
earlier where the L20 rank doesn't exist), pre-spell-damage gear:

| Class    | Spell                  | Rank @ L20 | Cast | Damage | DPS |
|----------|------------------------|-----------|------|--------|-----|
| Mage     | Frostbolt              | rank 4    | 2.5s | 91-101 | ~38 |
| Mage     | Fireball               | rank 3    | 3.0s | 70-100 | ~28 |
| Mage     | Arcane Missiles        | rank 4    | 3.0s channel | 90/wave × 5 | ~38 (burst) |
| Priest   | Smite                  | rank 4    | 2.0s | 64-77  | ~35 |
| Priest   | Mind Blast             | rank 3    | 1.5s | 86-92  | ~59 (cooldown-gated) |
| Warlock  | Shadow Bolt            | rank 3    | 2.5s | 71-90  | ~32 |
| Shaman   | Lightning Bolt         | rank 3    | 2.0s | 78-93  | ~43 |
| Druid    | Wrath                  | rank 3    | 1.5s | 36-44  | ~27 |
| Druid    | Moonfire               | rank 4    | instant | 30 + 64 dot | ~22 (over dot duration) |

**Median sustained spell DPS at L20: ~30-35.**

A wand at ~32-35 DPS would put the auto-attack build at sustained
parity with the most common cast-heavy build for each caster.

## Proposed approach

A single per-wand UPDATE pass keyed off level. Wand DPS = floor of
sustained spell DPS for the level band. Tentative targets:

| Level band | Spell DPS floor | Wand DPS target |
|---|---|---|
|  5-10 | ~10 | 10 |
| 11-20 | ~25-35 | 30 |
| 21-30 | ~40 | 40 |
| 31-40 | ~55 | 55 |
| 41-50 | ~70 | 70 |
| 51-60 | ~95 | 95 |
| 61-70 | ~125 | 125 |
| 71-80 | ~175 | 175 |

The actual targets pin against measured sustained spell DPS at each
band's mid-point. The pass preserves each wand's existing delay
(weapon speed is a flavor knob the original designers used to
distinguish wands aesthetically) and rescales `dmg_min1` and
`dmg_max1` so the resulting DPS lands on target.

Rescaling formula identical to the kit's: new mean damage = target
DPS × (delay / 1000), preserved min:max ratio.

## Open questions

- **Does the parity target scale with talents?** A priest with
  Imp. Wand Specialization (5/5) gains 25% wand damage. Setting the
  base wand to 100% spell DPS means a talented priest exceeds spell
  DPS while wanding. Is that intended? Trade-off: penalize the
  talent (set base wand to 80% spell DPS so talented = 100%), or
  reward it (let talented wanding actually beat casting).
- **Coefficient for `+Spell Damage` gear on wands.** Vanilla wands
  benefit from spell-damage gear at a much lower coefficient than
  spells (~0.05 per wand-speed-second vs ~1.0 for spells). If we
  leave the coefficient unchanged, gear scaling will pull spells
  ahead at high levels. Options: scale the coefficient up, or accept
  divergence and update the wand-parity targets at gear breakpoints.
- **PvP balance.** A caster who can auto-attack at spell DPS without
  spending mana has near-infinite sustain. In PvP, that breaks the
  mana-management subgame. Worth a PvP-specific cap (wand damage
  reduced by 50% in PvP?), or this stays a PvE-only design call.
- **Should wand subclass affect the target?** Different wand
  subclasses (Frost, Fire, Shadow, Arcane, Holy) currently have
  identical DPS profiles. Could the parity target track which
  caster class the wand "feels like" (Frost wand → Mage DPS;
  Shadow → Warlock; Holy → Priest)? Adds complexity but enables
  per-class fine-tuning.

## Files to Update (when the work is picked up)

| Path | Action | Note |
|---|---|---|
| `sql/vanilla/db_world.src/08-wand-spell-parity.apply.sql` | new file | UPDATEs every wand row in item_template to land at the level-band target |
| `sql/vanilla/db_world.src/08-wand-spell-parity.revert.sql` | new file | Restores canonical wand damage from a snapshot taken at apply time |
| `patches/E-patches.sh` | add | `patch_E020_vanilla_wand_spell_parity` + `unpatch_E020_*` functions following the E018 clone-pattern (snapshot originals into a sidecar table, mutate, sidecar holds the rollback data) |
| `issues/148h-class-specific-starting-equipment.md` | reference | When this is done, update 148h's wand DPS from 20 → 30 (or whatever final target) for the kit's Dusk Wand and Burning Wand clones |

## Cross-References

- `issues/148h-class-specific-starting-equipment.md` — kit work; sets
  initial wand DPS to 20, defers the proper rebalance here.
- `issues/declined/148m-vanilla-xp-and-talent-tuning.md` — XP and talent
  point grants (also declined); the L20 talent budget was the input to
  the "talented wanding" parity-question above.
- `issues/148j-pretrain-level-20-abilities.md` — what spells are
  trained at L20; informs the spell-DPS reference table.
