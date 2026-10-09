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

**A level counts in kills.** At level L, about L even-level kills take a
character to the next level: one kill at level 1, about 50 at level 50
("Level 50 should give you 50, approximately. One kill, level one."). So
an even-level kill gives about a L-th of the experience level L needs.

**Higher monsters are worth more kills.** A monster d levels above the
character is worth d more kills than an even-level one: at level 50, a
level-55 kill counts as 6 ("+5 extra kills worth").

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

1. **"One kill, level one", read literally?** A single kill taking a new
   character from 1 to 2 (with quests and buddies, level 5 would come in a
   handful of kills), or "about one" as the shape of the curve, the first
   levels still taking a few kills?
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
