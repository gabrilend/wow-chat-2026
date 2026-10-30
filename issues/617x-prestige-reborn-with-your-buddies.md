# 617x - Prestige: Reborn, With Your Buddies

## Status
- Created: 2026-10-12
- Phase: 6
- Parent: 617 (buddy bots)
- Related: 186 (gear of equal strength: worn gear swapped for its match at the new level),
  617a6 (buddies by stage: de-levelling, waiting, re-making),
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

**The item.** At max level, a bind-on-pickup item from Kael'thas in
Magisters' Terrace (the five-person dungeon, creature 24664) starts the
rebirth when used (owner, 2026-10-12: "Magister's Terrace"). What using it
looks like is still open.

**The owner, reborn.** The character goes back to level 1 and keeps
nothing (owner, 2026-10-12: "The Reborn Character should keep nothing for
now. It's not for everyone. Maybe... titles? achievements? guild name
maybe?"): gear, bags, bank, gold, professions, reputation, mounts, quests
and talents all go. Titles, achievements and the guild (the clan, 617l)
are the candidates for what stays; not decided.

**The buddies, reborn with them.** Each buddy keeps:
- its name (later, buddies may rename themselves once they can speak,
  "when they learn LLM capabilities");
- its tier: it appears for the owner at the same level it did before.
It is otherwise made anew when its tier is reached again: a new class,
talent shape (617g) and professions (617k). It keeps its race and
gender: since 2026-10-30 a buddy's race and gender change only when the
owner's do (617a, word for word there), so Sargobras offers it only the
classes its race can play. (Before 2026-10-30: where the new class
couldn't be played by its race, a blood elf paladin becoming a druid, it
took a race that could, "because they are being reborn same as you".
Overturned by the rule in 617a.)

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
2. The rebirth record: per owner, per tier, one profile (the latest
   version: class, shape, role, professions) and an appearance set for
   each race the buddy has been (617a), kept beside the stage record
   (617a6), so "someone familiar" can bring back the latest version.
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

1. (Answered 2026-10-12: Magisters' Terrace's, 24664.) Always, or a
   chance?
2. (Answered 2026-10-12: nothing, "for now".) Do titles, achievements, or
   the guild name stay? And what do they gain for it (a title, a mark,
   something that counts rebirths)?
3. Does the rebirth start where they stand, or back in a starting valley
   (the rotating valleys, 155d)?
4. Can a character be reborn more than once? **Answered 2026-10-30:**
   "again and again".
5. A buddy's level after the rebirth: "keep the same level that they
   appear for you" read as the tier (the level-30 buddy appears at 30
   again). Is that right, or should it stay at its old level (60) and
   wait? **Answered 2026-10-30** (the owner, word for word): "buddies
   will rejoin you once you hit the requisite level. This is why it's so
   important to keep them dormant in stasis." Each buddy waits dormant
   (the stage record's waiting stage, 617a6) and rejoins when the reborn
   owner reaches its tier's level.
6. Death knights: can one be reborn, and if so, as what (it starts at 55)?
   **Answered 2026-10-30** (the owner, word for word): "yes, with
   sargobras soul already given. We will need new functionality for the
   prestige path, because Sargobras takes the "skip story/do the story"
   check before requesting a soul. So we'll need a new menu just for
   prestigers (not a new option, but a new menu) that just has two
   options, "I want to skip the story" or "I want to see the story". Then
   it immediately jumps to as if the soul was given. Make sure we don't
   lose track of WHICH soul the original one was, so we can recreate the
   character if need be." A death knight is reborn as a death knight,
   the soul already given to Sargobras. A reborn death knight meeting
   Sargobras gets a menu of its own (a separate menu, not an extra line
   on the usual one) with two lines, "I want to skip the story" and "I
   want to see the story"; either goes straight on as if the soul had
   just been given. The record of which soul was given the first time is
   kept, so the character can be recreated if need be.
7. "Someone familiar" after two rebirths: the latest one only, or a
   choice among each one the tier has had? The owner, 2026-10-30: "all
   of them I think...? Explain more?" Explained in conversation (a slot's
   history of versions: paladin, then druid; "all" meaning a list of
   every past version to pick from). The owner's reply set the race rule
   (617a) instead; whether Sargobras lists every past version or only
   the latest is asked again. **Answered 2026-10-30** (the owner, word
   for word): "class and professions should change at the same time.
   Sargobras only brings the most recent version back. We just store one
   profile probably, then an appearance set for each race they've
   visited." Only the latest version comes back. Each buddy keeps one
   profile (its class, shape and professions, which always change
   together) and an appearance for each race it has been (617a).
