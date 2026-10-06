# 173b12 - Combat Text

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), combat in the client
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client has no combat.

## Intended Behavior

The original's Combat Text panel (reference page, *Interface* → *Combat
Text*), built with combat:

- **Numbers over the target**: damage (`CombatDamage`), periodic damage
  (`CombatLogPeriodicSpells`), pet damage (`PetMeleeDamage`), healing
  (`CombatHealing`), effects on the target (`fctSpellMechanics`, and on
  other players' targets, `fctSpellMechanicsOther`).
- **The player's own floating text** (`enableCombatText`) and what it
  shows, on/off each: entering and leaving combat, dodges / parries /
  misses, damage reduction, reputation, reactive abilities ready,
  friendly healers' names, combo points, low health and mana, energy
  gains, periodic energy gains, honour, auras.
- **How it floats** (`combatTextFloatMode`): scroll up, scroll down, or
  arc.

## Suggested Implementation Steps

1. With combat: one floating-text drawer, each kind of event checked
   against its switch.

## Open Questions

None yet.
