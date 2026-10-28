# Abilities that changed after The Burning Crusade: a report for the advanced profile

*Written 2026-10-27 for issues 1101 (the advanced profile) and 168a (ability
versions at Chromie), at the owner's ask: "I would however like a report on
each of the potential abilities for this profile's changes." Each ability's
two forms are described from the game's patch history as remembered, not
yet read from data: before one is built, its TBC numbers come from a TBC
description and are written as its own spell (`spell_dbc`), and the 3.3.5
form is read from this server's `Spell.dbc` (`scripts/lib/spell-data.lua`).
The column "what it carried" is why it matters for class identity, which is
the owner's reason: "Blizzard didn't just change them for balance, but also
for class identity."*

Ordered by class, the owner's named ones first.

## Paladin

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Seal of Command** (talent) | a chance on each melee hit (about seven a minute) of an extra strike of Holy damage from the weapon; its judgement a burst of Holy damage | a smaller Holy strike on every hit, to up to three targets | the slow two-hander's big, lucky hits |
| **Blessings** | ten-minute single blessings, half-hour greater ones given class by class (with a reagent); each paladin's blessing its own, one of each kind per target | fewer blessings, longer, simpler to share | the paladin as the party's quartermaster |
| **Blessing of Salvation** | a blessing: less threat, worn for a whole fight | a short "hand" spell instead | the tanks' and the others' blessing |
| **Blessing of Light** | a blessing that made heals on its target stronger | gone | the healer's helper |
| **Judgement** | unleashed the active seal (it ended), each seal its own judgement | three separate judgements, the seal staying | seal-twisting, the rhythm of seal and judgement |
| **Seal of Righteousness** | Holy damage on each swing by weapon speed | reworked, by attack power and spell power | the caster-paladin's seal |
| **Seal of Blood / of the Martyr** | the Horde's and Alliance's own seals (damage at a cost of health) | joined into one form | the faction's own flavour |

## Priest

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Racial priest spells** | each race's priests had two of their own: human Feedback and Desperate Prayer; dwarf Fear Ward and Desperate Prayer; night elf Starshards and Elune's Grace; undead Touch of Weakness and Devouring Plague; troll Hex of Weakness and Shadowguard; blood elf Consume Magic and Touch of Weakness; draenei Symbol of Hope and Fear Ward | gone; Devouring Plague, Fear Ward and Desperate Prayer given to all (or a talent) | a priest's race mattered: a dwarf for Fear Ward, an undead for the Plague |
| **Inner Fire** | a number of charges, used up by being hit | no charges, lasting | |
| **Holy Nova, Shadowform's limits** | Holy Nova a talent, Shadowform barring all holy spells | changed | the shadow priest's purity |

## Shaman

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Air totems** | Windfury Totem (an extra-attack chance on the party's weapons), Grace of Air, Tranquil Air, Wrath of Air: one at a time, so a choice | consolidated: Windfury a haste aura, fewer choices | the totem twist, the shaman's choices for its party |
| **Bloodlust / Heroism** | the shaman's party only | the whole raid | the party shaman as a prize |
| **Stormstrike** | two strikes and a debuff making the next nature hits stronger | changed | the enhancement rhythm |
| **Earth Shield** | charges, a talent at 41 points | similar; part of a longer tree | |

## Warrior

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Stances** | each ability tied to its stance, swapping costing rage | looser | stance dancing |
| **Sweeping Strikes** | a few hits cleaving, in battle and berserker stance | longer, any stance (in practice) | |
| **Rampage** (41-point fury talent) | attack power stacking with each crit | a passive crit aura | the fury warrior's build-up |
| **Intercept** | berserker stance only | changed | |

## Hunter

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Aimed Shot** | a cast time that broke the auto-shot rhythm, and a healing-reduction debuff | instant | the shot weaving of a TBC hunter |
| **Aspect of the Viper** | mana regeneration by intellect | by attack | the mana-hungry hunter |
| **Expose Weakness, Trueshot Aura** | raid-wide buffs from a hunter's talents | changed | the survival hunter's raid spot |

## Druid

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Lifebloom** | stacking to three, its bloom a big heal when it ran out, kept rolling | changed rules for the bloom | the TBC tree's "rolling" |
| **Tree of Life** | a form with an aura for the party and few spells allowed | a cooldown | the tree as a way of life |
| **Innervate** | by the target's spirit | by the druid's mana | |

## Rogue

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Poisons** | charges on the weapon, used up | no charges | the rogue's upkeep |
| **Expose Armor** | a big armour cut by combo points, against sunder | changed | the rogue's raid job |
| **Hemorrhage** | charges | changed | |

## Mage

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Water Elemental** | a 45-second summon on a cooldown | permanent (with a talent) | the frost mage's moment |
| **Arcane spells** | Arcane Blast stacks raising its own cost (a mana race) | similar, longer tree | the arcane mage's budget |

## Warlock

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Demonic Sacrifice** | the demon given up for a lasting buff | gone | the demonless warlock |
| **Curses** | Curse of Recklessness, of Shadow and of the Elements each a raid role | merged | the raid's curse-keeper |
| **Soul Link, Siphon Life** | talents of their trees | moved or gone | |

## Racial abilities

| Ability | In TBC | In 3.3.5 | What it carried |
|---|---|---|---|
| **Mana Tap and Arcane Torrent** (blood elf) | Mana Tap drained a target's mana into charges; Arcane Torrent spent them to restore mana (and silenced) | Mana Tap gone; Arcane Torrent alone, restoring the class's own power (energy for a rogue, runic power for a death knight) | the blood elf's hunger for magic |
| **Other racials** | each race's had its own shape (Stoneform's poison and bleed cleanse, the troll's berserking by health) | reworked in 3.0 | to be listed from the data, as above |

## Death knight

None: the class came with 3.3.5's expansion.

## How to read this

Each row is a candidate for the advanced profile's own form of the ability
(TBC form where the owner chooses). A per-character choice between the two
forms at Chromie (168a) was set aside on 2026-10-27, the owner: "I think
this system is replaced by the Advanced profile. For now at least." Rows
the owner names first: Seal of Command, the paladin blessings, the priest
racial spells.
