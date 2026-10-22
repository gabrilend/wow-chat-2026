# 625b - A Buddy's Weapon Preference, and the Talents That Follow It

## Status
- Created: 2026-10-22
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Blocked by: 625a (what each talent touches, which also says which
  talents are weapon-type talents)
- Related: 617g (talent shapes), 617r (buddy gear), 718 (death knight
  buddies' runeblades), 633 (death knight buddies' runes)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22, first:

> Also, can we modify it to also choose *gear* as well? For example, Arms
> Warriors should only equip items that correspond to the weapon type they
> chose in their talent tree. Death Knights should pick a 2h weapon unless
> they randomly rolled the 1h weapon talent, then they are two 1h weapons.
> Also we should ensure that if they pick one weapon type, like the combat
> rogue swords talent, then they should ONLY have swords. The exception is
> sometimes rogues want an offhand dagger? Can you give me a plan for this
> implementation?

Then, on the rogue and the general rule:

> the rogues should take a dagger if they have certain talents, like
> Combat Potency for 1h + offhand, or Focused Attacks for 2 daggers, which
> is beyond this server's max talent tree depth limit. I don't know how to
> generalize this, so let me think out loud a bit. So, poisons benefit
> from fast attack speed. If the buddy-bot rolls poison talents, like
> Improved Poisons, then they should prefer daggers. If they roll the
> sword talent, they should skip Improved Poisons and the dagger talent.
> Also Hemorrhage prefers daggers. Also some abilities like Ambush require
> daggers, so if they are among the talent points they pick, they daggers
> become more preferred...
>
> I think, maybe, instead, we should just... pick the weapon type specific
> talents, there aren't too many, and just assign one to each buddy-bot
> as their "weapon preference", and buddy-bots with talent profiles that
> include one of the weapon type selectors will only select the talent
> that corresponds to their preferred weapon type. BUT, if the buddy-bot
> finds a cool new weapon that is better than their current one, they'll
> update their weapon preference to use it. And, if they have one of the
> specific weapon-type specific talents, we can automatically switch it
> for them, applying however many talent points they had in the old one
> to the new one. We can do that automatically whenever their weapon
> preference is updated, and it only updates when they get a new weapon
> type that is stronger than their current weapon, and which they get to
> keep and can equip and use.

## Current Behavior

A buddy's gear is chosen by stat weights (617r, 625's weights) and its
kit; its weapon kind isn't tied to its talents. Death knight buddies
carry the Runed Soulblade or the story's great weapon (718), whatever
their talents. A buddy's talents are spent by its shape's plan (617g,
`src/lua-basic/buddy-talents.lua` with the talent spender library).

Which talents tie to a weapon type (3.3.5a; a weapon talent's spell names
the weapon kinds it works with in its "equipped item" fields, so 625a's
generator can list them from the data rather than by hand):

- **Warrior, Arms:** Poleaxe Specialization (axes and polearms), Mace
  Specialization (maces), Sword Specialization (swords); Two-Handed Weapon
  Specialization (two-handers).
- **Warrior, Fury:** Dual Wield Specialization (two weapons).
- **Rogue, Combat:** Sword Specialization, Mace Specialization, Fist Weapon
  Specialization, Dagger Specialization, Dual Wield Specialization.
- **Death knight:** Two-Handed Weapon Specialization (Blood) against Nerves
  of Cold Steel and Threat of Thassarian (Frost: one-handers in both
  hands).
- **Paladin:** Two-Handed Weapon Specialization (Retribution).
- **Shaman, Enhancement:** Dual Wield, Dual Wield Specialization.

## Intended Behavior

**A weapon preference per buddy.** Each buddy carries one weapon
preference: a weapon kind (sword, mace, axe, polearm, dagger, fist
weapon, staff...) and a grip (one two-hander, or two one-handers, or one
one-hander with a shield or off-hand item). It is drawn when the buddy is
made, from what its class and shape can use.

**The talents follow the preference.** Where a buddy's talent plan
includes a weapon-type talent, it takes the one for its preferred kind
and grip instead (a sword-preferring Combat rogue takes Sword
Specialization; a mace-preferring one, Mace Specialization), the same
number of points. Talents whose benefit depends on a weapon kind count
as weapon-type talents too: for a rogue, Improved Poisons and Hemorrhage
favour daggers, and a dagger preference takes them (and Dagger
Specialization) where a sword preference skips them for its own.

**It equips only its preference.** Weapons of another kind or grip are
never equipped, needed in a loot roll or bought, with one exception: a
rogue may hold a dagger in its off hand whatever its main-hand kind.

**The preference changes when a better weapon comes.** When a buddy gets
a weapon of another kind or grip that it can keep, can equip and use, and
that is stronger than its current weapon (by its stat weights), its
preference becomes that kind and grip, it equips it, and its weapon-type
talents are switched to the new kind's, moving the points over one for
one (a free respec of just those talents).

**Death knights:** a two-hand preference unless their rolled talents
include the one-hand ones (Nerves of Cold Steel, Threat of Thassarian),
then two one-handers. The runeblade rule (718: the 55 and 57 buddies carry
the Runed Soulblade) applies to two-hand preferences.

## Suggested Implementation Steps

1. Answer the open questions.
2. From 625a's generator: the weapon-type talents (each talent's weapon
   kinds and grip, from its spell's equipped item fields) and the
   weapon-dependent ones (Improved Poisons, Hemorrhage...; a short list
   by hand where the data doesn't say, kept beside the generated one).
3. The preference: a column on the buddy roster (kind, grip), drawn at
   creation.
4. The talent spender (`buddy-talent-spender`): before spending, the
   shape's plan is rewritten for the preference (swap each weapon-type
   talent for the preferred kind's twin; drop the weapon-dependent ones
   that don't suit, putting their points where the plan puts spare
   points).
5. Every weapon choice (the bot module's item usefulness check, the buddy
   kit, the death knight gear script, loot rolls, buying) asks "suits the
   preference?" first.
6. The switch: when a buddy receives a weapon (loot, quest reward, trade,
   mail), if it is of another kind or grip, usable, keepable and stronger,
   update the preference, equip it, and re-spend the swapped talents.
7. Tests: the plan rewrite (a Combat rogue shape with a mace preference
   ends with Mace Specialization, same points); the switch (a
   sword-preferring warrior given a stronger axe: preference axe, Poleaxe
   Specialization with the old points); a dagger allowed in a rogue's off
   hand.

## Open Questions

1. **Which talents depend on a weapon kind** beyond the named weapon
   talents (Improved Poisons and Hemorrhage for daggers, as you said):
   should the list also hold the abilities that need a kind (Ambush and
   Backstab need a dagger) so a shape whose plan leans on them draws a
   dagger preference from the start?
2. **The first draw:** at random among what the class can use, or
   weighted by the shape's talent plan (a plan with Improved Poisons
   draws daggers more often)?
3. **"Stronger":** by the buddy's stat weights for the item (damage per
   second and stats together), or by weapon damage per second alone?
