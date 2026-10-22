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

Then, the same day:

> I changed my mind, let's just say that only the weapon specific talents
> follow the preference. It's simpler, and allows for stranger builds.

> [a rogue may keep a dagger in its off hand] only if it doesn't have one
> of the talents that restrict weapon types. Also the rogue dagger talent
> also allows for fist weapons. I think the warrior axe talent allows for
> polearms too.

On weighting abilities by how many of a buddy's talents mention them:
"We might wind up in a situation where druids only cast Healing Touch for
example, because it's mentioned in the most resto talents by number.
So... maybe I'm leaning away from this one tbh." (Not planned; see 625.)

And on weapon speed:

> Gah! Weapon types are hard! How do you encourage buddy-bots to pick
> correctly suitable weapons, when some talent points scale with fast
> weapons, and others scale with slow? Maybe... Maybe we could like, cache
> some simulations or something, or each possible combination, that could
> maybe help them pick the right talents or gear somehow? What do you
> think?

## Current Behavior

A buddy's gear is chosen by stat weights (617r, 625's weights) and its
kit; its weapon kind isn't tied to its talents. Death knight buddies
carry the Runed Soulblade or the story's great weapon (718), whatever
their talents. A buddy's talents are spent by its shape's plan (617g,
`src/lua-basic/buddy-talents.lua` with the talent spender library).

The weapon-type talents of 3.3.5a (names as in this game version; a
weapon talent's spell names the weapon kinds it works with in its
"equipped item" fields, so 625a's generator lists them from the data and
confirms this list):

- **Warrior, Arms:** Poleaxe Specialization (axes and polearms), Mace
  Specialization (maces), Sword Specialization (swords), Two-Handed Weapon
  Specialization (any two-hander).
- **Warrior, Fury:** Dual Wield Specialization (two weapons).
- **Rogue, Combat:** Close Quarters Combat (daggers and fist weapons),
  Hack and Slash (swords and axes), Mace Specialization (maces), Dual
  Wield Specialization (two weapons).
- **Death knight:** Two-Handed Weapon Specialization (Blood) against Nerves
  of Cold Steel and Threat of Thassarian (Frost: a one-hander in each
  hand).
- **Paladin, Retribution:** Two-Handed Weapon Specialization.
- **Shaman, Enhancement:** Dual Wield, Dual Wield Specialization.

## Intended Behavior

**A weapon preference per buddy.** Each buddy carries one weapon
preference: a weapon group as the talents name them (axes and polearms;
maces; swords; daggers and fist weapons; swords and axes...) and a grip
(one two-hander, or a one-hander in each hand, or a one-hander with a
shield or off-hand item). It is drawn when the buddy is made, from what
its class and shape can use.

**Only the weapon talents follow the preference** (decided 2026-10-22).
Where a buddy's talent plan includes a weapon-type talent, it takes the
one for its preferred group and grip instead, the same number of points
(a Combat rogue preferring maces takes Mace Specialization where its plan
says Hack and Slash). Every other talent is taken as its plan says, so
strange builds can happen.

**It equips only its preference, when it has a weapon talent.** A buddy
whose talents include a weapon-type talent wears only weapons of that
talent's group and grip, in every hand. A rogue with no weapon-type
talent may hold a dagger in its off hand whatever its main hand. A buddy
with no weapon-type talent chooses by stats, as now.

**The preference changes when a better weapon comes.** When a buddy gets
a weapon of another group or grip that it can keep, can equip and use,
and that is stronger than its current weapon (by its stat weights), its
preference becomes that group and grip, it equips it, and its weapon-type
talents are switched to the new group's, moving the points over one for
one (a free respec of just those talents).

**Death knights:** a two-hand preference unless their rolled talents
include the one-hand ones (Nerves of Cold Steel, Threat of Thassarian),
then a one-hander in each hand. The runeblade rule (718: the 55 and 57
buddies carry the Runed Soulblade) applies to two-hand preferences.

**Fast and slow (open question 3).** Some talents and abilities do more
with fast weapons (poisons and other per-hit effects, off-hand hits),
others with slow ones (abilities that add the weapon's damage, a
two-hander's big swings). The weapon preference above doesn't decide
speed; how a buddy weighs a fast weapon against a slow one of its group
is open.

## Suggested Implementation Steps

1. Answer the open questions.
2. From 625a's generator: the weapon-type talents (each talent's weapon
   groups and grip, from its spell's equipped item fields).
3. The preference: a column on the buddy roster (group, grip), drawn at
   creation.
4. The talent spender (`buddy-talent-spender`): before spending, the
   shape's plan is rewritten for the preference (each weapon-type talent
   swapped for the preferred group's twin, same points).
5. Every weapon choice (the bot module's item usefulness check, the buddy
   kit, the death knight gear script, loot rolls, buying) asks "suits the
   preference?" first, for a buddy with a weapon-type talent.
6. The switch: when a buddy receives a weapon (loot, quest reward, trade,
   mail), if it is of another group or grip, usable, keepable and
   stronger, update the preference, equip it, and re-spend the swapped
   talents.
7. Tests: the plan rewrite (a Combat rogue shape with a mace preference
   ends with Mace Specialization, same points); the switch (a
   sword-preferring warrior given a stronger axe: preference axes and
   polearms, Poleaxe Specialization with the old points); a rogue without
   weapon talents keeps an off-hand dagger, one with Hack and Slash
   doesn't.

## Open Questions

1. **The first draw:** at random among what the class can use, or
   weighted by the shape's talent plan?
2. **"Stronger":** by the buddy's stat weights for the item (damage per
   second and stats together), or by weapon damage per second alone?
3. **Fast or slow, and simulations.** The owner asked whether cached
   simulations could guide it. A full combat simulation per class, talent
   plan and weapon is heavy; a middle way that gets most of the value: a
   small offline calculator that, for each class shape and each weapon
   speed band (fast, middling, slow, by hand), adds up the expected damage
   of the shape's own ability rotation (each ability's formula: weapon
   damage added, normalized speed, per-hit procs like poisons) against a
   standard target, and writes a table "shape → preferred speed band per
   hand". Buddies read the table; nothing runs in game. It would be
   regenerated when a shape changes. Worth building, or is weapon damage
   per second, with the preference above, good enough?
