# 178 - Experience Counted in Kills

## Status
- Created: 2026-10-08
- Phase: 1
- Profile: basic
- Related: 155 (the basic profile), 155b (experience rate stays 1x, its
  2026-09-23 answer), 617c2 (the proximity party: who is grouped, the
  74-yard experience radius), 617l (the clan guild), 617 (buddies)
- Priority: Medium

## Origin

The owner, 2026-10-08, asked "can we make exp rewards scale linearly with
level?", then, shown that a kill's experience already grows linearly
(5 x level + 45 at even level) while the experience each level needs does
not (8 kills at level 1, 506 at level 59):

> Killing a level 55 while you're level 50 should give you +5 extra kills
> worth at if you were fighting a level 50. Level 50 should give you 50,
> approximately. One kill, level one. levels per exp scale but you get more
> buddy-bots who help you earn exp.
>
> can we just... increase the range you can distribute EXP to just be
> distributed to your clanmates always? Then, you're grouped with anyone
> that you can interact with or heal - the 4 closest, sticky targetting.

## Current Behavior

Not built. Basic runs the stock experience (155b: rate 1x). At even
level a kill gives 5 x level + 45; a monster above you gives up to 20%
more per level of difference (capped at 4 levels); one below gives less,
and nothing once it is grey (`Acore::XP::BaseGain`, `Formulas.cpp`). The
experience each level needs comes from `player_xp_for_level` (400 at level
1, 20,800 at 20, 74,300 at 40, 172,000 at 59). In a group, a kill's
experience is split among members within 74 yards of the monster
(`MaxGroupXPDistance`), with a bonus for groups of three or more.

## Intended Behavior

**The aim** (owner, 2026-10-08): "basically... level as hard as you can
with as minimal of gear as you can, and fight to the last."

**A level counts in kills: ten per level number.** The first reading (L
kills at level L: "One kill, level one") was too fast ("we would level
too fast. Gotta replace this with something better ... maybe 1/10th as
fast?"). At level L, about 10 x L even-level kills reach the next level:
10 at level 1, 500 at level 50. An even-level kill gives a (10 x L)-th of
what level L needs. The owner, on the comparison below: "our curve scales
faster, but... not too bad? ... Anyway our system makes more sense I
think."

**A kill is worth the monster's level over yours.** Corrected the same
day (owner, 2026-10-08: "it should give +5 levels so like, +5 the exp
bonus of a level one. So if level 1 gives 10 exp then you'd get 50exp. So
if you're level 50 and the target is level 55 then if you get 500 exp for
a kill then after the level adjustment you get 550."): each level the
monster stands above you adds a level-one's share, so a kill gives an
even-level kill's experience times (monster level / your level). At 50, a
level-55 kill is x1.1; at 10, a level-15 kill is x1.5; at 1, a level-6
kill is x6. (The first reading, "+5 extra kills worth", made a +5 kill
worth six even ones at every level; that is not it.)

Kills to level (even-level kills: 10 x level; monsters above: 10 x L x
L / (L + d)), stock beside it (`BaseGain`: +5% a level above, at most
+20%; `player_xp_for_level`, computed 2026-10-08):

| Level | ours even | +1 | +2 | +3 | +4 | +5 | stock even | stock +5 |
|---|---|---|---|---|---|---|---|---|
| 1 | 10 | 5 | 3 | 2 | 2 | 2 | 8 | 7 |
| 5 | 50 | 42 | 36 | 31 | 28 | 25 | | |
| 10 | 100 | 91 | 83 | 77 | 71 | 67 | 80 | 67 |
| 20 | 200 | 190 | 182 | 174 | 167 | 160 | 143 | 120 |
| 30 | 300 | 290 | 281 | 273 | 265 | 257 | 199 | 166 |
| 40 | 400 | 390 | 381 | 372 | 364 | 356 | 303 | 253 |
| 50 | 500 | 490 | 481 | 472 | 463 | 455 | 410 | 342 |
| 59 | 590 | 580 | 571 | 561 | 553 | 544 | 506 | 422 |

So the curve is about a fifth slower than stock at even level, and the
reward for a harder monster is large while levels are low and fades as
they climb: the same five levels up halve a level-10's kills to two
thirds, a level-59's by under a tenth.

**Quests leave the players' road** (180): with quests gone from players,
kills are where experience comes from.

**Buddies make up the climb.** The experience levels need still rises
("levels per exp scale"); a character gains buddies as it levels (one
per ten levels, 617a), and they earn experience with it ("you get more
buddy-bots who help you earn exp").

**Shared with the clan, always** ("can we just... increase the range you
can distribute EXP to just be distributed to your clanmates always?"): a
kill's experience reaches every clanmate (the character's buddies, 617l),
wherever they are, not only those within 74 yards in a group.

**Grouping by who you can help** ("Then, you're grouped with anyone that
you can interact with or heal - the 4 closest, sticky targetting."): the
group is the four nearest characters the player could interact with or
heal, and once one is in, it stays in until another is clearly nearer
(sticky), as a held target is.

## Suggested Implementation Steps

1. Decide the open questions.
2. The kill's experience as a rule with no server in it: level, monster
   level, the clan's size and spread; tested against the owner's numbers
   (level 1: one kill; level 50: about 50; level 55 at 50: 6).
3. A source patch to `Acore::XP::BaseGain` (or the kill-reward step) for
   basic, gated so other profiles keep stock experience; the clan's share
   in the kill reward (`KillRewarder`).
4. The grouping rule in the buddy module's proximity party (617c2).

## Open Questions

1. (Answered 2026-10-08) **The pace:** ten kills per level number, not
   one.
2. **Monsters below you:** a monster d levels below: worth d fewer kills
   (a level-45 kill at 50 counting as nothing, or as a fraction), the stock
   shrinking, or still one kill?
3. **Sharing with the clan:** does each clanmate get the whole kill's
   experience (everyone levels as fast as the one fighting), or the kill
   split among them (more buddies, smaller shares)? And players in one
   clan: the same rule for them?
4. **The group of four nearest:** this replaces 617c2's rule (leave past
   75 yards, join inside 60, owner, 2026-09-27)? "Anyone that you can
   interact with or heal": buddies only, or any friendly player too? And
   "sticky": how much nearer must another be before it takes a place?
5. **Quests:** quest experience stays stock, or is counted in kills too?
6. **Monsters below you:** the same rule read downward (a level-45 kill at
   50 worth 45/50 = 0.9 of an even one, and grey monsters still worth
   something), or the stock shrinking and nothing from grey?
7. **A cap above:** monster level / your level without a ceiling (a
   level-10 monster at level 1 is worth ten even kills)?
