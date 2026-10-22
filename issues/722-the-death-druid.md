# 722 - The Death Druid: Part Death Knight, Part Druid

## Status
- Created: 2026-10-22
- Phase: 7 (custom class / race-class infrastructure)
- Related: 705 (custom class selection), 709 (custom class Lua format),
  710 (custom class resource bars), 711 (custom class configuration
  schema), 716 (class combinations), 718 (death knights on basic), 718g
  (no Death Grip)
- Priority: Low
- State: an idea; open questions first

## Origin

Verbatim, 2026-10-22:

> can we make issue files for a custom class that's a "death druid", part
> death knight, part druid? it should have rejuvenation and regrowth and
> nature's swiftness and thorns and entangling roots but not nature's
> grasp or barkskin. it shouldn't have any DK diseases, and no self
> healing from DK spells.

> the death druid should have death coil, but it should heal all friendly
> targets.

## Current Behavior

Nothing exists. The custom class work (705, 709-711, 716) is planned: a
custom class there is a stock class whose abilities are chosen from
several classes' trainers, re-costed in its own resource. The game client
knows only the ten stock classes (its class list is in its own data
files), so a new class shows in the client as one of them.

Facts that shape the design (stock 3.3.5a):

- A death knight has no mana. It spends runes and runic power. Every druid
  spell named here costs mana, so as they stand a death knight can't cast
  them at all.
- Death Coil (death knight) harms an enemy, or heals a friendly undead
  target only (the death knight's own ghoul, or itself with a talent).
- Nature's Swiftness is a druid restoration talent, not a trained spell.
- The death knight's diseases are Frost Fever and Blood Plague (and the
  spells that apply or spread them: Icy Touch, Plague Strike, Pestilence,
  Unholy Blight, Death and Decay's ties). Its self-healing comes from
  Death Strike, Rune Tap, Vampiric Blood, Mark of Blood, Death Pact,
  Blood Presence, and talents (Improved Blood Presence, Butchery's runic
  power aside).

## Intended Behavior

A death druid is a death knight in the client's eyes (its look, its
runes) with a druid's healing gifts and none of a death knight's
diseases or self-healing:

- **Has**, from the druid: Rejuvenation, Regrowth, Nature's Swiftness,
  Thorns, Entangling Roots.
- **Never has**, from the druid: Nature's Grasp, Barkskin.
- **Has**, from the death knight, a changed Death Coil: it heals every
  friendly target, not only undead ones (open question 3 on what "all"
  means).
- **Never has**, from the death knight: any disease (Frost Fever, Blood
  Plague, and the spells whose purpose is to apply or spread them), or
  any of its self-healing.
- Its druid spells cost runic power (decided 2026-10-22).

## Suggested Implementation Steps

1. Answer the open questions.
2. The class as a configuration in the 711 schema: the stock class it
   rides on (death knight), the spells it keeps, the spells it never
   learns (a list, refused at learning and at trainers), the spells it
   gains.
3. The resource for the druid spells (710): their cost moved from mana to
   runic power or runes (a server-side spell-data override), checked
   against the client, which also checks power before it casts.
4. Death Coil changed for it: its heal effect targets any friendly unit
   (a spell script on the server, for death druids only).
5. Nature's Swiftness taught as a spell, not a talent.
6. Tests: a death druid learns only its list; each druid spell casts and
   costs what was chosen; Death Coil heals a living friend; no disease
   spell can be learned.

## Open Questions

1. (Answered 2026-10-22: "runic power.") The druid spells cost runic
   power. How much each costs (a share of its mana cost, or a flat
   amount by how strong the spell is) is for the building step.
2. **How is one made?** Chosen at creation (705's selection NPC, or
   Sargobras at the soul trade), or a path a death knight takes after the
   story (718a's allegiances)?
3. **"Heal all friendly targets":** Death Coil heals any one friendly
   target (where stock it heals only undead ones), or every friendly
   target near the one aimed at, at once?
4. **What else it keeps** from the death knight: presences, the ghoul,
   Death Grip (718g removes it from death knights), Death Gate, Runeforging,
   the talent trees (all three death knight trees, or druid's restoration,
   or a tree of its own)?
5. **Which druid ranks:** the highest each level allows, learned from a
   druid trainer, or given as the death druid levels?
