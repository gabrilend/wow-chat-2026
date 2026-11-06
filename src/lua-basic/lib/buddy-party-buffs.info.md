# buddy-party-buffs.lua

The Lua model of a party's buff plan (issue 617c5, step 2): which aura
each paladin keeps up, which totem of each element each shaman puts down,
whether a hunter gives Aspect of the Wild and a priest Shadow Protection,
which blessing each paladin puts on each member, and which judgement each
paladin uses. Pure decisions: touches no server object; tested offline by
`scripts/test-buddy-party-buffs`. Nothing in the game asks it yet.

## The checklist

Every party-wide buff belongs to one category (`Buffs.CATEGORIES`), a
line on the party's checklist, whoever gives it. Two buffs the game won't
let stack are one line: the game's stacking groups (`spell_group` in the
world database) and its "exclusive resistance" auras decide which. So a
paladin's fire resistance aura and a shaman's fire resistance totem are
one line, and so are Totem of Wrath and Flametongue Totem, and Mana Spring
Totem and Blessing of Wisdom. Devotion Aura and Stoneskin Totem are two.

The lines the party wants, most needed first:
- the resistances whose school `party.resist` says matters (the combat
  system's call), the one that matters more first;
- then the rest that help this party. Concentration, spell power and
  spell haste need a healer or caster; strength and agility and melee
  haste need weapon users; mana regeneration needs mana users. Armor and
  Stoneskin aren't wanted against casters, and Grounding only against
  them.

What players give ticks lines off. Buddies fill the rest: each line that
can be filled beside the ones above it is filled. Among the ways to do
that, the one with the most lines given by a giver whose talents improve
that buff, and then the most given with a line's best spell.

## Functions

### `Buffs.plan(party) -> plan`
The whole plan for the party's buddies:
- `auras[paladin]`, `totems[shaman][element]`, `aspects[hunter]` (none:
  the hunter keeps its own), `prayers[priest]`;
- `blessings[receiver][paladin]`, `judgements[paladin]`;
- `checklist`: each wanted line, `{ category, by }`, where `by` is the
  giver's name, or nil when nobody can give it;
- `said`: the lines buddies tell the party (an improved aura kept up, a
  switch of aura).

Players' own choices (`giver.gives`) are read and planned around, never
changed. The party's fields are listed at the top of the file.

### `Buffs.wishes(receiver, paladins, covered) -> list`
A member's blessings, most wanted first, in this order:
1. its stated wish;
2. blessings a buddy paladin's talents improve that it can use;
3. Wisdom, when its mana is under `LOW_MANA` (35%);
4. the usual for its role.

Left out: what it said no to, and a blessing whose effect a party-wide
buff already gives (`covered`, by category name: Wisdom beside Mana
Spring), unless it is the wish.

### `Buffs.judgements(party, taken) -> list`
The judgements on a target in the order paladins take them: Light first
when the party's health shortfall is the larger, Wisdom first when its
mana shortfall is, then the other, then Justice. `taken` (a player's) is
left out. In the plan, each paladin gets only one it knows
(`knows["judgement of light"]` and so on).

### `Buffs.parse_wish(text) -> { wish } | { avoid } | { clear } | nil`
A blessing asked for in a whisper, or in party or raid chat, said
naturally: `kings`, `Kings please`, `can you do might instead?`, `can I
get wisdom`, `BoW?`. Also `no might` or `please don't give me sanctuary`
to say no, and `anything` or `no preference` to clear. A message is a
wish only when it is plainly one, so `you might want to heal` and `I need
a new bow` are not.

### `Buffs.hear(receiver, wish)`
Applies a parsed wish to a member (it holds until logout or a new one).
