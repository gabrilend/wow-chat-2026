# 625a - What Each Talent Touches, Read from the Game's Own Tables

## Status
- Created: 2026-10-22
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Blocks: 625 step 3 (weights), 625b (gear by talents)
- Priority: Medium
- State: planned

## Origin

The owner, 2026-10-22: "Where are we at with picking buddy-bot abilities
depending on the contents of their talents? Question, can we do it
mechanically by finding out exactly which spells the talent modifies,
through sql or something?"

## Current Behavior

Nothing built (625 is an idea). Bots choose abilities by their strategy's
fixed priorities; talents taken don't move them, and item set bonuses
(625, added 2026-10-22) don't either.

How the game itself knows what a talent changes (3.3.5a, the client's
Spell.dbc, which the server reads too): every class spell carries its
class (its "spell family") and a 96-bit set of family flags naming
which kind of spell it is. A talent is a spell whose effects modify
other spells, and each such effect carries a 96-bit class mask: it
affects every spell of the same family whose flags overlap that mask.
The server applies talents exactly this way (`SpellInfo::IsAffected`). So
"which spells does this talent modify" has an exact, mechanical answer:
the same family, overlapping bits. Talents that teach a spell (an effect
that learns one) name it directly. Set bonuses are spells too
(ItemSet.dbc lists each set's bonus spells and their piece counts) and
are read the same way.

## Intended Behavior

A generated table: for every talent rank and every set bonus, the class
abilities it affects or teaches, and how (more damage, less cost, shorter
cooldown, a new effect: from the effect's aura type). Generated once from
the client's tables, as the tome generator reads them, and kept as data
the buddy code loads. Re-generated when the game data changes (never, on
3.3.5a).

## Suggested Implementation Steps

1. A generator (`scripts/generate-basic-talent-touches`, LuaJIT like the
   other generators) reading Talent.dbc (each talent's rank spells),
   Spell.dbc (family, family flags, each effect's class mask and aura
   type, learned spells) and ItemSet.dbc (set bonus spells, pieces
   needed).
2. For each talent rank and set bonus: every player-learnable spell of the
   same family whose flags overlap an effect's mask (player-learnable:
   on a class trainer, a talent, or a starting spell), with the aura type
   of the effect that matched.
3. Output: a Lua data file (talent or set → ability spell ids, each with
   a kind: damage, cost, cooldown, cast time, new effect) and a
   human-readable listing per class, to check by eye (for example,
   Improved Heroic Strike touches Heroic Strike's ranks and nothing else).
4. A test: a handful of known pairs read from the table (Improved
   Rejuvenation touches Rejuvenation; Sword Specialization touches no
   ability, it is a weapon talent: 625b).

## Open Questions

None yet.
