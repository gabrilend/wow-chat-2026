# 625a - What Each Talent Touches, Read from the Game's Own Tables

## Status
- Created: 2026-10-22
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Blocks: 625 step 3 (weights), 625b (gear by talents)
- Priority: Medium
- State: in progress (the table built; set bonuses not yet)

## Origin

The owner, 2026-10-22: "Where are we at with picking buddy-bot abilities
depending on the contents of their talents? Question, can we do it
mechanically by finding out exactly which spells the talent modifies,
through sql or something?"

And 2026-10-29: "We could use the embedding of the icon and the name and
the text to maybe also guide it a little bit. An embedding that says
"improved the effect of your rejuvenation spell by 15%" will probably
embed pretty well with casting rejuvenation more often, but we should
check token-by-token to find word-by-word relationship associations. And
then maybe prioritize or increase in value the relationships that are a
little unseen, like "all of your subtlety spells" or "weapon attacks" and
similar."

## Current Behavior

**The table is built (2026-10-30)**: `scripts/generate-talent-touches`
reads Talent, TalentTab, Spell and SkillLineAbility from the client's
files and writes `src/lua-basic/data/buddy-talent-touches.lua` (for each
talent: the abilities it improves, how, and whether broadly) and the
listing `docs/talent-touches.md`, to check by eye. 829 talents; 484
improve at least one ability (2,843 links); a talent that is itself an
ability (Insect Swarm, Swiftmend) is marked as such. Checked by
`scripts/test-talent-touches` (a quick test): Improved Rejuvenation,
Starlight Wrath (both Wrath and Starfire), Improved Heroic Strike,
Insect Swarm, and Naturalist's physical damage reaching Shred but not
Cat Form. Set bonuses (ItemSet.dbc) are not read yet. Nothing reads the
table yet: the weights (625 step 3) come next.

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

### Read from the game's own data (decided 2026-10-30)

The owner, 2026-10-30, on the icon: "basically we want to take the
embedding of the talent icon, and see what it most closely matches to. We
shouldn't have a shortcut built in, it should arise naturally from our
other systems." And, told that the game records exactly which spells each
talent changes: "oh, we can probably just use this instead of the
embedding system. More reliable, and we still get character from it.
Maybe not as much character, but we can expand it later if needed."

So each talent rank, and each set bonus, is read two ways, both from the
game's own tables, and nothing else:

1. **The masks**: the same family with overlapping flags (the exact
   answer, what the server itself applies).
2. **The broad targets**: an effect aimed at a school of magic, a weapon
   kind or a mechanic, expanded to every ability of the class that
   matches (all its Shadow spells; all its abilities that strike with a
   weapon). These are the "a little unseen" ones the owner named ("all of
   your subtlety spells", "weapon attacks"), which a family mask alone
   misses.

**Not built, kept as a later expansion** (planned 2026-10-29, set aside
2026-10-30): reading a talent by its icon, and by its tooltip's words
token by token with a text embedding. The icon was to be compared by an
embedding of the picture, not by a shortcut (a talent and an ability
sharing an icon number, as Improved Rejuvenation and Rejuvenation share
icon 64: such a rule is not built in). If the game's data proves too
plain for a buddy's character, the embeddings come back as an extra
reading, checked against the masks.

**The broad ones count for more** (the owner: "prioritize or increase in
value the relationships that are a little unseen"): a talent that
touches many abilities would otherwise spread thin and count for little
on each, and its abilities would never be favoured. Its weight on each
ability it covers is raised, so a buddy with "all of your Shadow spells"
talents leans toward its Shadow spells as a whole. This is not 625's
dropped idea of counting how many talents name an ability (that made a
druid cast only Healing Touch): the raise is per broad talent, by points
spent in it.

## Open Questions

1. How much should the broad talents be raised: to count as much on each
   ability they cover as a talent naming one ability does, or by half
   of that?
2. Should the icon and the words count on their own (a link no mask
   shows), or only as a check of the masks and the broad targets?
   **Answered 2026-10-30:** neither is built; the game's own data alone
   (above), the embeddings kept for later.
