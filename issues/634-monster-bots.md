# 634 - Monster Bots: Evil Playerbots with Monster Pages

## Status
- Created: 2026-10-22
- Phase: 6
- Related: 155z13 (monsters with stat pages: the first step), 617t1 (stand-ins:
  characters made for a scene), 628a (the bake: a stand-in's look baked into a
  creature, the rest kept as data), 620 (every playerbot plays by the house
  rules), `notes/larp-renfair-visual-style.md` (the visual idea below)
- Priority: Low
- State: an idea; the shape chosen (a creature with a page), the rest open

## Origin

Verbatim, 2026-10-22, asked whether monster stat pages are still wanted now
that monsters do crit:

> monsters could eventually be given player pages. Like, evil playerbots
> that players have to fight. Actually, can we create issue files for that?
> they shouldn't be horde-and-alliance, but rather monster themed, with
> monster stats and only sometimes gear. Though maybe if we make a LARP
> style renfair themed version we could have them be humans with gear that
> corresponds to the creature they are standing in-for. But that's a concept
> for a visual style that we should write down somewhere.

## Current Behavior

Monsters are creatures: a level, a rank, damage ranges and spells from the
creature tables, a flat 5% crit chance, no stat page (155z13). Playerbots
(the bot module) are characters of the playable races and classes, of the
Horde or the Alliance; basic runs none at random (155b), only buddies and
stand-ins (617t1). Nothing fights players as a character would.

## Intended Behavior

(As read; the open questions decide.)

- **Evil playerbots, monster-themed:** opponents that fight with a
  character's page (abilities, talents, a stat page), but are monsters:
  monster stats and looks, not of the Horde or the Alliance, and only
  sometimes wearing gear.
- **A visual style for them, written down for later:** a LARP / Renaissance
  fair version, in which they are humans in costume, wearing gear that
  matches the creature they stand in for (a "wolf" in fur and a wolf-head
  hood). Recorded in `notes/larp-renfair-visual-style.md`; a choice for
  later, not part of this issue's first build.

## Suggested Implementation Steps

1. Answer the open questions.
2. The page: built on 155z13's monster stat pages, adding abilities chosen
   the way a class's are (a list per monster kind), so the creature fights
   with a rotation rather than its stock few spells.
3. Or the other way in: a stand-in-style bot character (617t1) on a hostile
   monster faction, its look baked from the creature it replaces (628a),
   fighting with the bot module's class logic.
4. Where they appear: in place of chosen monsters (named ones, elites), or
   as their own encounters.

## Open Questions

1. **Creature with a page, or character in monster form?** (a) A creature
   (as now) given a character's stats and a rotation (cheaper; the server
   handles thousands), or (b) a real bot character on a monster faction,
   looking like the monster (it plays exactly like a player would, but
   each one is a logged-in character and costs like a buddy)?
2. **Where they fight:** a few special encounters (a rare elite that plays
   like a player), whole dungeons, or the open world?
3. **"only sometimes gear":** gear that can drop when they die, or gear as
   part of their look only?

## Answers, 2026-10-22

1. **Creatures with a page, (a):** "it's easier to process NPCs is my
   understanding so we'd create an NPC and just simulate the bot's
   behavior based on what the NPC is positioned near and such. So we'd
   have the bot cast a spell, and we can do it all on the server without
   having to go back to the player for input. Should lessen our demands
   I think." Right in effect: bots also run wholly on the server (no
   player's game is asked anything), but each is a full character, with
   its session, inventory and saving; a creature carries far less. So a
   monster bot is a creature whose fighting is decided on the server by
   bot-like rules from what is around it (who is near, its health, its
   cooldowns), casting its spells as a bot would.
2. **Where they fight:** "they spawn from dungeons and raids and explore
   the world like playerbots and fight players when they see them. They
   should be level appropriate for the zone they spawn from. Yes, this
   means evil bots in the Ghostlands from Zul'Aman, but not in Darkshore."
   So they come out of the entrances of dungeons and raids, roam the
   zone around the entrance as bots do, and attack players they see; their
   level is that zone's (the Ghostlands' 10-20 for those leaving Zul'Aman,
   not Zul'Aman's 70). A zone with no dungeon or raid entrance (Darkshore)
   has none. Open: how many at once per entrance, and how often they come
   out?
3. **Baking** (asked 2026-10-23: "does that mean that since we're
   simulating the bots anyway, with their inventory and everything, there
   isn't really a reason to bake them for this purpose?"): a monster bot
   is a creature, so it has no inventory or character to bake from: it
   already is a creature with a monster's look. Baking (628a) turns a
   dressed character's look into a creature; it would come in only for
   the LARP style (people in costume), where a dressed human look has to
   become a creature's.
