# 633 - Death Knight Buddies Runeforge Their Weapons

## Status
- Created: 2026-10-22
- Phase: 6
- Related: 718 (death knight buddies, their runeblades), 625b (weapons
  chosen by talents: one-hand or two-hand), 621 (a strong enchant on a
  new weapon), 723 (Death Gate there and back)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22, after "what are the current DK capability for
buddy-bot runeforging?":

> Well we should make one. DK buddy-bots should seek to have a runeforged
> weapon. They should pick one randomly, and everytime they go to Acherus
> they can pick a new one.
>
> But, there's some that are just... worse, like for example the 1h to 2h
> versions of the same rune. So they should of course pick the best one
> that suits their gear.

## Current Behavior

None in practice (read 2026-10-22):

- Death knight buddies know the Runeforging spell (53428; the bot module
  teaches it to every death knight bot with Death Gate and the
  Deathcharger), but nothing ever uses it.
- The bot module has no rune-enchanting behaviour, and its enchant table
  (`playerbots_enchants`) has no death knight rows.
- The buddy kit's random weapon enchant (from level 30, 621) goes on the
  starting weapon, which the death knight gear script then replaces with
  the Runed Soulblade or the story's great weapon (718) and destroys. So
  Throszurg's Runed Soulblade has no enchant at all.

The runes (3.3.5a; each is a Runeforging spell that puts a permanent
enchant on the death knight's weapon, cast at a runeforge in Acherus or
the Ebon Hold):

| Rune | Weapon | The other-hand twin |
|---|---|---|
| Rune of the Fallen Crusader | any | |
| Rune of Razorice | any | |
| Rune of Cinderglacier | any | |
| Rune of Lichbane | any | |
| Rune of Spellbreaking | one-hand | Spellshattering (two-hand) |
| Rune of Spellshattering | two-hand | Spellbreaking (one-hand) |
| Rune of Swordbreaking | one-hand | Swordshattering (two-hand) |
| Rune of Swordshattering | two-hand | Swordbreaking (one-hand) |
| Rune of the Nerubian Carapace | one-hand | Stoneskin Gargoyle (two-hand) |
| Rune of the Stoneskin Gargoyle | two-hand | Nerubian Carapace (one-hand) |

(The one-hand and two-hand twins do the same job; the two-hand one is
stronger, as a two-hander has one weapon to carry it.)

## Intended Behavior

- A death knight buddy seeks a runeforged weapon: a weapon without a rune
  is a reason to visit a runeforge (in the Ebon Hold or Acherus).
- At a runeforge it picks a rune at random among those that suit its
  weapon (a two-hander never takes a one-hand rune when the two-hand twin
  exists, and the reverse), and runeforges each weapon it holds.
- Every visit to Acherus (the Ebon Hold) it may pick a new one, again at
  random among those that suit.
- A new weapon (a runeblade from the gear script, loot) arrives without
  a rune, so it seeks one again.

## Suggested Implementation Steps

1. Answer the open questions.
2. The rune list as data: rune spell, enchant id, weapon kinds it suits
   (read from Spell.dbc: each rune spell's equipped item fields), and its
   twin.
3. The choice: for each weapon held, the runes that suit it, minus a
   one-hand rune on a two-hander whose twin suits better; one at random.
4. The visit: a buddy errand (`buddies_town.cpp`'s errands, as the
   mailbox and vendor) that walks it to the nearest runeforge when its
   weapon has no rune and the Ebon Hold is near, or on each visit there;
   casting the rune at the runeforge (the bot casts Runeforging's rune on
   its weapon; or, where the bot module can't, the enchant applied
   directly while it stands at the runeforge, as the kit applies its
   enchants).
5. The gear script (718) keeps a weapon's rune when it swaps between the
   same weapon, and no longer destroys a runed weapon for an unruned copy.
6. Tests: the choice on each weapon kind (two-hander never gets a
   one-hand rune; one-handers never get a two-hand one); in game, a death
   knight buddy at the Ebon Hold runeforges its Soulblade.

## Open Questions

1. **"Every time they go to Acherus":** the Ebon Hold over the
   Plaguelands (map 0), where Death Gate goes, or Acherus in the Enclave
   (map 609, only during the story)?
2. **How often a new pick:** every visit, or only some visits (say a
   one-in-three chance), so a buddy's rune is part of who it is for a
   while?
3. **The owner's say:** may the owner ask a buddy for a rune ("rune of
   razorice"), as 626's keyboard and orders do?
