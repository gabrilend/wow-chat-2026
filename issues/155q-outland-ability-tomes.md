# 155q - Level 61–80 Ability Tomes from Azeroth

## Status
- Created: 2026-09-25
- Phase: 1
- Parent: 155
- Related: 155h (Naxxramas at 60, where the Wrath-era tomes drop), 405
  (ability tome system, another profile's rank-agnostic tomes; the
  mechanism to reuse), 156 (expert, 61–80, where these abilities are
  ordinary)
- Priority: Low (built 2026-09-25 as E037; in-game test and scaling review pending)

## Origin

Verbatim, a note left in the project root (`new-issue-please-sort`,
2026-09-24):

> for the basic profile, I was wondering, if we made class abilities that
> required between levels 61 and 80 learnable from tomes? I think there's
> issue files for a different profile for tomes for each ability. Then, we
> could make them drop from high level Outland mobs. Just a thought,
> continuing progression...

## Current Behavior

**Built 2026-09-25** as install step E037 (not yet tried in game; the
per-ability scaling review, step 4, is not done):

- `scripts/generate-basic-ability-tomes-sql` reads the stock class trainer
  lists (all levels, kept per class, since Plate Mail is taught to two
  classes), the client's Spell.dbc (name, rank; a "teaching" entry is
  unwrapped to the spell it teaches, none at 61–80 today) and
  SkillLineAbility.dbc (race masks), and writes one row per 61–80 entry
  into the GENERATED block of
  `sql/basic/db_world.src/22-ability-tomes.apply.sql`. Each row: the book's
  item id (1557001 upward), the spell, the class and level, the spell the
  reader must already know (found by walking the previous-rank chain down
  through trainer entries; the first link no trainer teaches is the talent
  or granted spell, such as Pyroblast or the Mangle talent's two forms, or
  a starting spell every character has), the races allowed (six books are
  one faction's: the two paladin seals, Heroism, Bloodlust, the two Portal:
  Shattrath), the title ("Slam V") and the "Teaches Slam (Rank 5)." line.
  Left out: Teleport: Dalaran and Portal: Dalaran (Northrend is closed,
  155s). Run it for the current count; 793 when built.
- The SQL copies each class's stock Ahn'Qiraj book (Manual, Libram, Guide,
  Handbook, Codex, Tablet, Tome, Grimoire, Book; death knights copy the
  warrior's manual and are titled "Runestone of") and sets the name,
  description, class, races, the Learning spell (483) and the ability with
  the learn trigger, the required spell and level 60. Rare, **unbound** (tradeable; Ritz, 2026-09-25: "I think they should not be bound"), sells
  for 10 gold, as the stock books.
- Two pools, every book equally likely: reference loot 1557901 (61–70) and
  1557902 (71–80). Drops: Ahn'Qiraj 40 16.67% per loot boss (the bug trio
  each, only the last is lootable; the twin emperors 8.33% each), Ahn'Qiraj
  20 4.17% per boss, each Emerald Dragon three books always; Naxxramas 10%
  per boss in the 10-person size and 25% in the 25-person size (2.5 times,
  Ritz: "About 2.5x as many."), and the Four Horsemen's two chests
  likewise.
- `basic_155q_books` keeps the list for the checker. Nothing stock changes;
  the revert deletes what was added.
- Tested: `scripts/test-basic-sql-in-ram` (apply, re-apply, revert with the
  exact checksum, apply); `scripts/validate-basic-state` checks every book
  (class, level 60, spells, required spell, pool) and every drop row.

Stock, for reference: basic stops at level 60, so its characters never
learn anything a trainer teaches from 61 to 80. That is about 800 trainer
entries across the classes (new abilities and higher ranks of known ones),
read 2026-09-25 from the stock trainer tables:

| Class | Warrior | Paladin | Hunter | Rogue | Priest | Death knight | Shaman | Mage | Warlock | Druid |
|---|---|---|---|---|---|---|---|---|---|---|
| Entries at 61–80 | 48 | 64 | 60 | 42 | 91 | 65 | 113 | 107 | 98 | 107 |

Issue 405 already designs rank-agnostic tomes for another profile: one
"Tome of Rejuvenation" teaches whichever rank the reader may learn next.

## Intended Behavior

Level 61–80 class abilities (new ones and higher ranks) become learnable at
60 from tomes that drop: progression past the level cap through what a
character finds.

**Tomes drop only in Azeroth** (Ritz, 2026-09-25, replacing the note's
Outland mobs): "can we make tomes only drop from Azeroth? We should treat
Outland as alien and strange, and Azeroth is where we go to focus our
strength. It's fitting I think that the WotLK tomes would then be dropping
from Naxxramas." So the Wrath-era abilities' tomes drop from Naxxramas (at
60 on basic, 155h). (The file keeps its name, `155q-outland-ability-tomes`,
so links to it stay valid.)

## Suggested Implementation Steps

1. Answer the open questions below with Ritz. (Done, except the two
   below.)
2. (Done) A generator reads each class's 61–80 trainer entries (death knights
   included) and writes one class book per entry in the stock way: the
   "Learning" spell (483) first, the ability second with the learn
   trigger, limited to that class, a stock book icon, required level 60.
   No script.
3. (Done) The same generator writes the drop tables: Ahn'Qiraj 20 and 40 and the
   Emerald Dragons for the 61–70 books, Naxxramas for the 71–80 books,
   every book at equal odds.
4. Review scaling per ability (a table per class of each ability's numbers
   at 60) and scale down where needed.
5. Test on the RAM database (done); then in game, a level-60 reading a book:
   tooltip, icon, learning.

## Open Questions

- (Answered 2026-09-25) Every 61–80 entry, new abilities and higher ranks
  alike (Ritz: "For all the abilities, not just the ones that have tomes
  already").
- (Answered 2026-09-25) New tome items (Ritz: "let's hope that newly
  created items show correctly..."). What makes that likely: the 3.3.5
  client asks the server for an item's name, quality and tooltip text the
  first time it sees the item and caches the answer, so a new item's text
  shows correctly. What the server can't send is art: each tome must
  point at an icon the client already has (reuse a stock book's display
  id), and its on-use effect must be a spell the client already knows
  (reuse a stock "learning" style spell; the server's Lua then teaches the
  rank). No AIO and no client patch needed (405's Inscription recipes
  would need one; dropped tomes skip recipes). Test first in game with
  one tome: tooltip, icon, use.
- How a tome teaches, two ways:
  - Ritz's (2026-09-25): "we could just... fake the tooltip. If they use
    the item then we cast the spell on them with lua." The tooltip text is
    written to say what it teaches; Lua, on use, teaches it.
  - The stock game's own way, found 2026-09-25: 66 stock class books
    already work like this with no script (Codex of Holy Word: Shield III,
    Grimoire of Doom, Tome of Tranquilizing Shot, ...): the item's first
    spell is the client's "Learning" spell (483), its second is the
    ability, marked "learn this spell" (trigger 6), and it is limited to
    one class. The server teaches it natively and the client draws the
    ability's own tooltip, so it can't drift from what is learned
    (honest tooltips, `docs/design-principles.md`). It costs one item per
    rank (about 800, written by the generator) instead of one
    rank-agnostic tome per ability.
  (Answered 2026-09-25) The stock class-book way ("Let's use option 1").
  The scripted way stays with 405 and the custom classes, which need it.
- (Answered 2026-09-25) Where: Azeroth only; the Wrath-era (71–80) tomes
  from Naxxramas. The Burning Crusade–era (61–70) tomes (Ritz): "Ahn
  Quiraj. Both 20 and 40, 40 has 4x the drop rate, but it's still pretty
  rare - usually 1 or 2 per raid amongst 40 people. They all drop from 20
  and 40 at the same rate, no priority given to higher level spell tomes.
  Also, emerald dragons are guaranteed to drop three." So: every 61–70
  tome at equal odds; an Ahn'Qiraj 40 clear gives about 1–2 in all, an
  Ahn'Qiraj 20 clear a quarter of that rate per kill; each of the four
  Emerald Dragons (Ysondre, Lethon, Emeriss, Taerar) always drops three.
  (Ritz added "They are from The Burning Crusade"; the dragons are
  vanilla world bosses, so this is read as: they drop the Burning
  Crusade–era tomes.)
- (Answered 2026-09-25) Naxxramas drops the 71–80 tomes at Ahn'Qiraj 40's
  rate, about 1–2 per clear ("Sure.").
- (Answered 2026-09-25) Scaling "probably depends on the ability": decided
  per ability, not by one rule (715, linear ability scaling, is related).
  How to review them (by class, a table of each 61–80 ability's numbers
  at 60) is for the building step.
- (Answered 2026-09-25) Death knights get tomes too ("yeah!").
- (Answered 2026-09-25) No quest rewards; the Wrath-era tomes drop from
  Naxxramas only ("the original design is correct").
- (Answered 2026-09-25) Death knights have no stock class book; theirs are
  titled "Runestone of …" ("runestone it is"), copied from the warrior's
  manual (same icon). "Sigil" was avoided: death knight relics are already
  named "Sigil of …".
- (Answered 2026-09-25) The 25-person Naxxramas drops about 2.5 times the
  10-person's books ("About 2.5x as many."): 25% per boss against 10%.
