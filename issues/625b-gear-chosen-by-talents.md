# 625b - Buddies Wear the Weapons Their Talents Are For

## Status
- Created: 2026-10-22
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Blocked by: 625a (what each talent touches)
- Related: 617g (talent shapes), 617r (buddy gear), 718 (death knight
  buddies' runeblades), 633 (death knight buddies' runes)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22:

> Also, can we modify it to also choose *gear* as well? For example, Arms
> Warriors should only equip items that correspond to the weapon type they
> chose in their talent tree. Death Knights should pick a 2h weapon unless
> they randomly rolled the 1h weapon talent, then they are two 1h weapons.
> Also we should ensure that if they pick one weapon type, like the combat
> rogue swords talent, then they should ONLY have swords. The exception is
> sometimes rogues want an offhand dagger? Can you give me a plan for this
> implementation?

## Current Behavior

A buddy's gear is chosen by stat weights (617r, 625's weights) and its
kit; the weapon type its talents favour isn't considered. Death knight
buddies carry the Runed Soulblade or the story's great weapon (718),
whatever their talents.

Which talents tie to a weapon type (3.3.5a; a weapon talent's spell names
the weapon kinds it works with in its "equipped item" fields, so this
list too can be read mechanically by 625a's generator rather than kept by
hand):

- **Warrior, Arms:** Poleaxe Specialization (axes and polearms), Mace
  Specialization (maces), Sword Specialization (swords); Two-Handed Weapon
  Specialization (two-handers).
- **Warrior, Fury:** Dual Wield Specialization (two weapons), Titan's Grip
  (two two-handers, past basic's talent cap, 155g).
- **Rogue, Combat:** Sword Specialization, Mace Specialization, Fist Weapon
  Specialization, Dagger Specialization (Combat's own), Dual Wield
  Specialization.
- **Death knight:** Two-Handed Weapon Specialization (Blood) against Nerves
  of Cold Steel and Threat of Thassarian (Frost: one-handers in both
  hands).
- **Paladin:** Two-Handed Weapon Specialization (Retribution).
- **Shaman, Enhancement:** Dual Wield (and Dual Wield Specialization).
- **Hunter, Survival/Beast Mastery:** none by type (ranged weapon kind by
  stats).

## Intended Behavior

A buddy's weapon choice follows its talents:

- **A weapon-type talent taken** (Sword Specialization, Mace
  Specialization...): the buddy wears only that kind, in every hand that
  holds a weapon. **Rogues** may keep a dagger in the off hand whatever
  their main-hand talent (open question 1).
- **Two-handed against dual wield:** a buddy whose talents favour
  two-handers wears one two-hander; one whose talents favour dual wield
  wears two one-handers. **Death knights:** a two-hander, unless their
  rolled talents include the one-handed talents (Nerves of Cold Steel,
  Threat of Thassarian), then two one-handers.
- **No weapon talent:** as now, by stats.
- Every place a buddy picks a weapon follows the rule: its kit, loot
  rolls and needs, buying, trading with the owner (623), and the death
  knight runeblade rule (718), which yields to the talents.

## Suggested Implementation Steps

1. Answer the open questions.
2. From 625a's generator: each talent's weapon kinds (its spell's
   equipped item class and subclass mask), as data.
3. A buddy's allowed weapons: from its talents (the shape's talent plan,
   617g, so it is known before the points are spent), a set of weapon
   kinds per hand, and one-hander pair or two-hander.
4. Every weapon choice (the bot module's item usefulness check, the buddy
   kit, the death knight gear script) asks "allowed?" first; a weapon not
   allowed is never equipped, rolled need on or bought.
5. Talent re-rolls (617g: the owner's respec re-rolls its buddies) re-check
   the weapons: one no longer allowed is swapped at the next town visit.
6. Tests: a sword-specialised rogue offered an axe and a sword takes the
   sword; a frost death knight with Threat of Thassarian takes two
   one-handers; a blood death knight a two-hander.

## Open Questions

1. **The rogue's off hand:** always a dagger allowed in the off hand
   whatever the main-hand talent, or only for rogues using daggers'
   openers (Ambush, Backstab, which need a dagger in the main hand)?
2. **Two weapon talents taken** (a warrior with both Mace and Sword
   Specialization, rare in a shape): either kind allowed, or the one with
   more points?
3. **The death knight runeblade** (718: the 55 and 57 buddies always carry
   the Runed Soulblade, a two-hander): a dual-wield death knight buddy gets
   two one-handers instead, and the Soulblade rule is for two-hand death
   knights only?
