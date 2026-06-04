# 717 - Universal Weapon Skills with Talent Training Cost

## Status: Open

## Phase: 7 (Character Identity — universality)

## Origin

Conversation 2026-05-12. Companion to the enchanting-system-update vision (notes/
vision-enchanting-system-update.md) which established the principle that *magic
empowers the wielder, not the geometry of the slot*. This issue applies the same
principle to weapon proficiency: any class can wield any weapon, with a balancing
cost paid in talent training time.

## Current Behavior

In 3.3.5a AzerothCore, each class has a hard-coded set of weapon proficiencies:

- **Warrior** — all weapons except wands
- **Mage** — daggers, one-handed swords, staves, wands (no plate, no two-handers)
- **Paladin** — most melee, no daggers, no ranged
- **Hunter** — most melee + all ranged
- **Priest** — daggers, one-handed maces, staves, wands
- **Rogue** — daggers, one-handed swords/maces/axes, bows, crossbows, guns, fist
- **Shaman** — daggers, fists, one/two-handed maces and axes, staves, shields
- **Warlock** — daggers, one-handed swords, staves, wands
- **Druid** — daggers, fists, one-handed maces, two-handed maces, polearms, staves
- **Death Knight** — most melee, no ranged

Proficiencies are granted by spell IDs at character creation and at trainer visits.
A character without a proficiency for an equipped weapon suffers a large damage
penalty (red weapon glow).

Talent points and training time are uniform across classes — talents arrive at
configured levels (10 points at levels 5, 8, 11, 14, 17, 20 per issue 805) at
whatever speed XP gain dictates.

## Intended Behavior

### Universal Weapon Proficiency

Every character, regardless of class, **starts with proficiency in every weapon
type**. No class-locked weapon restrictions.

A mage can wield a two-handed axe. A priest can equip a crossbow. A rogue can
swing a polearm. The weapon glows white in all hands.

The character's *effectiveness* with a given weapon is governed by stats,
talents, and abilities — not by a binary proficiency gate.

### The Trade — Slower Talent Training

In exchange for universal weapon access, **talent training takes 3x as long**.

The intuition: the character is spending mental and physical effort attuning to
every weapon type, which leaves less bandwidth for specialization. Versatility
costs depth.

Two readings of "3x as long per weapon skill" are possible — to be resolved
during implementation:

- **Reading A (flat-3x — recommended):** Talent training is a flat 3x slower
  across the board. The cost is paid once, conceptually, for the bundle of
  universal weapon skills granted at character creation. Simple to implement,
  predictable for players.

- **Reading B (per-skill multiplier):** Talent training scales with the number
  of weapon skills the character has. With ~13 weapon types, this would multiply
  talent training time by ~39x, which is likely too punishing. This reading
  would only make sense if the player chose how many weapon skills to retain.

Recommendation: **Reading A**. Reading B is captured here only so the design
intent can be reconsidered if the flat-3x feels insufficiently costly or
disconnected from the gain.

### Where the 3x Applies

The 3x slowdown applies to **whatever mechanism currently produces talent points**.
Per issue 805 (chunked-talent-points), the project awards 10 points at levels 5,
8, 11, 14, 17, 20. The 3x cost can be implemented as:

- **Option 1: XP gain reduction.** The character earns 1/3 XP. Talent milestones
  arrive 3x later naturally, but everything else (ability training availability,
  ambush spawn level, etc.) also slows. Simple but broad.

- **Option 2: Talent-specific XP track.** A separate "talent XP" counter
  accumulates at 1/3 the rate of normal XP, decoupled from level. Talent
  milestones arrive 3x later while leveling pace remains normal.

- **Option 3: Tier-based talent gating.** Talent tiers (per issue 802) unlock at
  levels 5, 8, 11, 14, 17, 20 normally — but for universal-weapon characters,
  they unlock at 15, 24, 33, 42, 51, 60. Hits the level-20 cap problem.

- **Option 4: Trainer-based time gate.** Talent training requires visiting a
  trainer (per issue 707 aio-tiered-talent-trainers) with a 3x cooldown between
  applications.

Recommendation: **Option 2** — talent XP track. Decoupling talent progression
from level progression preserves the rest of the system unchanged and keeps the
cost localized to the trade-off being made.

## Suggested Implementation Steps

1. **Grant universal proficiency on character creation.** Identify the spell IDs
   for each weapon proficiency in `acore_world.spell_dbc` (or wherever they
   reside) and apply all of them via a player-login Lua hook in mod-ale. See
   issue 701 for the pattern of granting abilities through trainer/hook flow.

2. **Strip class-locked proficiency restrictions** from custom-class definitions
   (issue 709 custom-class-lua-format). The `weapons.known` and
   `weapons.learnable` fields become obsolete or are repurposed as cosmetic
   hints.

3. **Implement talent-XP track.** Add a per-player counter that accumulates at
   1/3 the rate of normal XP. Talent point awards in the issue-805 chunked
   system trigger off this counter instead of player level.

4. **Document the trade-off** in the character-creation flow. The custom-class
   selection NPC (issue 705) should explain to the player: *"All classes wield
   all weapons. Talent training is 3x slower in exchange."*

5. **Visual feedback.** When a player levels up but the talent counter has not
   reached a milestone, show a brief in-chat message: *"Talent attunement
   progressing — 33% of the way to your next talent chunk."* So the slowed pace
   is visible, not mysterious.

6. **Test with existing custom classes** (knight per issue 709). Verify the
   knight, which already had broad weapon access, behaves correctly under the
   new system — no double-granting, no spell-ID conflicts.

## Affected Files (anticipated)

- `src/lua/extensions/_Misc.ext` or a new `src/lua/weapon-universality.lua` —
  proficiency-granting hook
- `src/lua/levelling.lua` (currently disabled — see git status) — talent-XP
  track addition
- `src/custom-class-json/*.json` and any Lua class definitions — strip
  proficiency restrictions
- Possibly `docs/class-spells-level-1-20.md` — update the weapon column to
  reflect "all" universally

## Related Issues

- **709** custom-class-lua-format — defines current weapon proficiency schema
- **706** knight-custom-class — example class that needs adjustment
- **805** chunked-talent-points — the talent award mechanism the 3x cost
  modifies
- **802** talent-tier-limit — interacts with how talents unlock
- **707** aio-tiered-talent-trainers — alternative cost-gate vector (Option 4)
- **701** quest-spells-to-trainers — Lua pattern for granting abilities

## Related Documents

- `notes/vision-enchanting-system-update.md` — the universality principle that
  motivated this issue (any item, any rating → any class, any weapon)

## Open Questions

- **Confirm Reading A** (flat-3x) over Reading B (per-skill multiplier). Likely
  Reading A but the user should sign off explicitly.
- **Confirm Option 2** (talent-XP track) over Options 1, 3, 4. Each has
  different blast radius on other systems.
- **Class identity preservation.** If every class wields every weapon, what
  distinguishes a warrior from a rogue at level 1? Only the starting ability set
  and the role-flavor of those abilities. This may or may not be sufficient
  identity. Consider whether *some* small weapon-skill cost (e.g. visible
  weapon-skill-up training time) is desirable for thematic reasons, or whether
  pure universality is the goal.
- **Death Knights** start at level 1 in Everland (issue 206). Do they get the
  same universal-weapon grant at level 1, or is theirs delayed to match their
  scaled progression?
- **PvP scaling.** If two players meet and one is on the 3x talent track and the
  other was an earlier character with full-speed talents, the older character is
  much stronger at the same level. Is this intended (a one-time conversion cost
  for existing characters) or should all existing characters retroactively
  receive universal-weapon proficiency and the 3x talent slowdown?

## Notes

The mirror with the enchanting vision is exact: *universality on the
benefit side, cost paid in a single coherent currency (required-level for
enchants, talent-training-time for weapon skills)*. The design is consistent
across systems.
