# 621 - A Strong Enchant on a New Weapon

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 617a4 (the buddy's starting kit), 617r2 (its gear from a
  gearset), 185 (the level-up command), 187 (after a level or class
  change), 148u (the first-login sharpening: a temporary enchant), 622
  (the buddy's weapon record: an enchant changes what a weapon does)
- Priority: Medium
- State: built for buddies' kit weapons, 2026-10-15; syntax-checked, not yet
  rebuilt or run

## Origin

Verbatim, 2026-10-15:

> can we also have the weapons enchanted with a powerful enchant? For
> example, fiery weapon or something...

Asked whether buddies or players: "either target is fine." Asked for the
choices: "give me a list."

Answers, 2026-10-15 (verbatim), on Fiery Weapon, Icy Chill,
Lifestealing and Unholy Weapon: "can do these. crusader too strong." And
which goes on which weapon:

> totally random. this is a buff to melee combat. spellcasters, using
> that parallel knowledge structure we mentioned earlier, should learn to
> possibly prioritize melee over spellcasting at certain times but not
> others. How and why is up to them to solve.

## Current Behavior

Then (verbatim): "no, only when they are instantiated for the first time.
Their starting gear weapon, for each of their level tiers they spawn as,
is enchanted with the potential weapon enchantment. But only after level
30."

**Built for buddies, 2026-10-15** (`buddies_kit.cpp`, the kit's
enchants): the weapons the starting kit puts in a main or off hand (not
a shield or a held item), for a buddy above level 30, when it is made or
made again at a tier (617a6), get one of Fiery Weapon (803), Icy Chill (1894),
Lifestealing (1898) or Unholy Weapon (1899), chosen at random, in the
item's permanent enchant slot. A re-dress (`.buddy kit`, a stand-in's
new level) enchants nothing. From level 30 (owner, 2026-10-15: "above level 29, 30 and up").
The next enhancements by level are 624's. An enchant number the server's tables lack is
named in the kit's problem line. Not yet: the weapons of the level-up
command (185) and the class-change tool (187), and players.

Before:
A new buddy's weapons (from its tier's white gearset, `buddies_kit.cpp`)
carry no enchant. A player's carry one only from 148u's first-login
sharpening (a temporary stone or oil). Nothing enchants a weapon after a
level-up or a class change.

The game client's tables do hold every permanent weapon enchant: read
2026-10-15 from `data-files/dbc/SpellItemEnchantment.dbc` and the
enchanting spells in `Spell.dbc` that apply them (effect 53, "enchant
item"). The ones that fit basic's levels 1-60 (classic enchanting):

| Enchant | Number | What it does |
|---|---|---|
| Crusader | 1900 | now and then heals and gives +100 strength for a while |
| Fiery Weapon | 803 | now and then burns the target for extra fire damage |
| Icy Chill | 1894 | now and then slows the target's movement and attacks |
| Lifestealing | 1898 | now and then drains the target's life to the wielder |
| Unholy Weapon | 1899 | now and then curses the target, lowering its damage |
| Demonslaying | 912 | now and then stuns a demon and adds damage against demons |
| Superior Striking | 1897 | +5 weapon damage (one-hand) |
| Superior Impact | 1896 | +9 weapon damage (two-hand) |
| Agility | 2564 | +15 agility (one-hand) |
| Strength | 2563 | +15 strength |
| Spellpower | 2504 | +30 spell power |
| Healing Power | 2505 | +29 spell power (healing) |
| Mighty Intellect | 2568 | +22 intellect |
| Major Intellect (2H) | 1904 | +9 intellect |

Stronger, from the later expansions (above basic's band, listed for the
choice): Mongoose 2673, Executioner 3225, Berserking 3789, Black Magic
3790, Massacre (2H, +110 attack power) 3827, Mighty Spellpower 3834.
The scratch reader that printed this list is
`enchants.lua` (session scratchpad, not kept); a permanent reader belongs
in `scripts/` if the list is regenerated.

## Intended Behavior

Every weapon a buddy is given when it is made (and a character's weapon
after 185's level change or 187's class change) carries a strong permanent
enchant chosen by what its wielder does: melee by strength or agility, a
caster by spell power, a healer by healing power, as the owner picks from
the table. The enchant is part of the weapon from the first moment, never
a later chore.

## Suggested Implementation Steps

1. The owner picks the enchants (the open question).
2. The choice as one table in configuration: role or talent shape to
   enchant number, beside the gearset tuning in `buddies_kit.cpp`.
3. When the kit equips a main or off hand, apply the enchant to the
   permanent slot (the item's permanent enchantment slot, as an
   enchanter's work would), and log a weapon the enchant can't go on (a
   one-hand enchant on a two-hander).
4. The same for the level-up command's and the class-change tool's new
   weapons.
5. In game: a new buddy at 30 and at 60, its weapon's tooltip.

## Open Questions

1. (Answered 2026-10-15: totally random, of the four melee procs.)
2. (Answered by the same choice: only the four classic procs.)
3. Players too, or buddies only? ("either target is fine": buddies
   built; players wait on 185 and 187.)
