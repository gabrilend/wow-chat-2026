# 617x - Prestige: Reborn, With Your Buddies

## Status
- Created: 2026-10-12
- Phase: 6
- Parent: 617 (buddy bots)
- Related: 617a6 (buddies by stage: de-levelling, waiting, re-making),
  617b (Sargobras, who chooses buddies), 617g (talent shapes), 617k
  (buddy professions), 155f (Outland dungeons, Kael'thas), 718 (death
  knights' buddies come by level)
- Priority: Medium
- State: planned; open questions below must be answered before building

## Origin

Verbatim, 2026-10-12:

> Also, can we add a way to "prestige" your character when at max level?
> Maybe an item dropped by Kael'Thas and bind-on-pickup. Your buddy-bots
> should keep their same name (which they'll be able to change eventually
> at will when they learn LLM capabilities) and keep the same level that
> they appear for you, but they should pick new classes, spec profiles,
> and professions, unless when the player talks to Sargobras they say "I
> am looking for someone familiar..." which is an option only available if
> you already have a buddy-bot created for you at that level. It's okay if
> the buddy-bots have to change race, for example if they were a Blood Elf
> Paladin and they turn into a Tauren Druid, because Blood Elves can't
> become druids. They are being reborn same as you. However, if they can,
> they should try and stay the same race and gender.

## Current Behavior

Nothing of this exists. A character at basic's cap (60) stays there. Its
buddies (617a) are one per tier (levels 1, 10, 20, ... 60, seven slots),
each a character on the owner's hidden companion account, with a class,
race, talent shape and role fixed when Sargobras's choice was made. The
stage system (617a6) can already take a buddy out of the world while its
owner is below its tier, keep a record of it, and make it again at the
owner's level when the owner comes back up.

## Intended Behavior



**The buddies, reborn with them.** Each buddy keeps:
- its name (later, buddies may rename themselves once they can speak,
  "when they learn LLM capabilities");
- its tier: it appears for the owner at the same level it did before.
It is otherwise made anew when its tier is reached again: a new class,
talent shape (617g) and professions (617k). Where it can, it keeps its
race and gender; where the new class can't be played by its race (a blood
elf paladin becoming a druid), it takes a race that can, "because they
are being reborn same as you".

**"Someone familiar."** At each tier, Sargobras offers "I am looking for
someone familiar..." alongside the classes and races, but only when the
owner already had a buddy at that tier before the rebirth. Choosing it
brings that buddy back as it was (class, race, shape, professions), made
at the tier's level, instead of drawing it anew.

Death knights (718): a death knight player's buddies come at 55, 57, 59
and 60, and it never meets the wandering Sargobras. How a death knight is
reborn is an open question.

## Suggested Implementation Steps

1. Answer the open questions.
2. The rebirth record: per owner, per tier, the buddy as it was before
   the rebirth (class, race, gender, shape, role, professions), kept
   beside the stage record (617a6), so "someone familiar" can read it.
3. The item: a world-database step adding the item (bind on pickup) to
   the chosen Kael'thas's loot, and the Lua that runs the rebirth on use.
4. The owner's reset to level 1 (the server's own level command, as the
   death knight reset tool does), and the roster's rows marked "reborn":
   each tier owed again, its buddy kept (name kept) but waiting (617a6's
   stage 1) until the tier is reached.
5. Sargobras's menu: the "someone familiar" option when the tier has a
   reborn record; otherwise the class or race pick as now, and the drawn
   buddy is the kept character re-made (new class: its race kept where
   the class allows, else the nearest allowed race of its faction; gender
   kept).
6. Re-making a kept character as a new class: the server stores class in
   the character row; a class change needs its spells, talents, skills,
   action bars and gear cleared and rebuilt (as 617a6's re-making does for
   level). To find out first: whether the core tolerates a class change
   on an existing character, or the buddy must be a new character given
   the old name (deleting the old one).
7. Tests: offline (the menu offers "someone familiar" only with a record;
   a race kept when allowed, changed when not; names kept), then in game.

## Open Questions

3. Does the rebirth start where they stand, or back in a starting valley
   (the rotating valleys, 155d)?
4. Can a character be reborn more than once?
5. A buddy's level after the rebirth: "keep the same level that they
   appear for you" read as the tier (the level-30 buddy appears at 30
   again). Is that right, or should it stay at its old level (60) and
   wait?
6. Death knights: can one be reborn, and if so, as what (it starts at 55)?
7. "Someone familiar" after two rebirths: the latest one only, or a
   choice among each one the tier has had?
