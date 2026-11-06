# buddy-party-buffs.lua

The Lua model of a party's buff plan (issue 617c5, step 2): which aura
each paladin keeps up, which blessing each paladin puts on each member,
which judgement each paladin uses, and which totem of each element each
shaman puts down. Pure decisions: touches no server object; tested
offline by `scripts/test-buddy-party-buffs`. Nothing in the game asks it
yet.

## Functions

### `Buffs.plan(party) -> plan`
The whole plan for the party's buddies: `auras[paladin]`,
`blessings[receiver][paladin]`, `judgements[paladin]`,
`totems[shaman][element]`, and `said`, the lines buddies tell the party
(an improved aura kept up, a switch of aura). Players' own choices
(`giver.gives`) are read and planned around, never changed. The party's
fields are listed at the top of the file.

### `Buffs.wishes(receiver, paladins) -> list`
A member's blessings, most wanted first: its stated wish; blessings a
buddy paladin's talents improve that it can use; Wisdom when its mana is
under `LOW_MANA` (35%); the usual for its role. What it said no to is left
out.

### `Buffs.judgements(party, taken) -> list`
The judgements on a target in the order paladins take them: Light first
when the party's health shortfall is the larger, Wisdom first when its
mana shortfall is, then the other, then Justice; `taken` (a player's) left
out.

### `Buffs.parse_wish(text) -> { wish } | { avoid } | { clear } | nil`
A whispered wish: a blessing's name or short form ("kings", "BoW"), "no",
"not" or "don't" before it to say no, "no preference" or "anything" to
clear.

### `Buffs.hear(receiver, wish)`
Applies a parsed wish to a member (it holds until logout or a new one).

## How buffs are shared out

For each kind (auras, a member's blessings, an element's totems) the
ranked list is handed to distinct givers who know them: the best that can
all be given at once, in rank order; among the ways to give those, the
one that hands the most to givers whose talents improve them. Auras and
totems are ranked by the threats: a resistance when its school is at least
`RESIST_SHARE` (40%) of the damage taken lately, largest first; then the
others that help this party (no Devotion or Stoneskin against casters,
Grounding only against them, Concentration and caster totems only with a
healer or caster, Windfury and Strength of Earth only with weapon users,
Mana Spring only with mana users).
