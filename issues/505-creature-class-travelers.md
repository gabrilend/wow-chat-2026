# 505 - Creature-Class Travelers (Wandering Combat NPCs)

## Status
- Created: from earlier `issues/wandering-dogs` idea-stub (preserved verbatim below)
- Phase: 5 (Friendly Encounters / Travelers)
- Priority: Low (idea stage; viability TBD)

## Original Idea (Verbatim)

The text below is preserved exactly as written in the original
`wandering-dogs` file. It is the primary description and source of
truth for what this issue is about. Implementation may diverge but
the *intent* lives here.

---

can we make it so that the creatures outside of the list of creatures defined as
the monsters that spawn in the game like animals and humanoids and elementals or
whatever we'll have to look specifically actually elementals should probably be
both anyway can we have them wander around as a traveller spawn one for each
level range for each classtype, that walks around and fights enemies. The
"track" of NPC that spawns should change to a new value every 10 levels, and
each class should draw from a different creature type. If there are too many,
then the creature type that has the most creatures can be split between two of
the classes. Shared. This process repeats if there's more - it depends on how
many creature types aren't being spawned as the evil creatures (plus elementals)
(because they can do both) and then we take the number of base classes in the
game (10 or 11 I forget) and distribute the creature types between them,
dividing them into portions if we need to. Anyway, the creatures that spawn as
travellers are chosen from the creatures at the player's level range at that
level range. They will wander around and fight any monsters they see. They're
like, friendly combat NPCs. Also sometimes for specific interactions between
levels there'll be interesting interactions but those have to be pre-programmed
and we can maybe make an rmail mailbox for user-submitted interactions. Like
an innkeeper petting a dog, or a meat-cleaver (butcher) feeding a dog or a dog
who wagged it's tail at some merchant who really likes that dog and gives it
attention and snacks when they see it. Users can program their own and the
system won't remember who has created what - unless it's deleted, of course.
The thing about an rmail inbox is you don't know who sent what - this is by
design. ALL THINGS ARE ANONYMIZED.

this is simply a sanitization procedure for privacy reasons, you must understand
that only user-submitted data is sanitized in this way. This is to act as a
"platform" like reddit or the internet, that users might submit cool things to.
And no, I don't want to make money from this. My rent could be 2000$ and I'd be
happy.

anyways the combat travellers would wander around and fight monsters. And they
are chosen from the same set pool of creatures that we decided at compile time,
sorta like the "banned creature ID's" tables in ambush.lua or whatever.

The custom classes would inherit the creature-types of the class that they
inherit stat-growth curves from.

---

## Distilled Behavior (Reference)

For reading convenience. The verbatim text above is authoritative; this
distillation is approximate.

- **Combat travelers** spawn alongside other travelers (per Phase 5
  traveler system) but engage hostile monsters on sight.
- **Selection pool** = creatures from the base game *not* in the
  ambush-spawn pool (the "banned creature IDs" exclusion in
  `src/lua/ambush.lua`). Plus elementals, which can appear in both.
- **Class assignment** — each base class is assigned a creature type
  (humanoid / beast / elemental / etc.). If there are more classes than
  creature types, the most-populous types get split (shared) between
  classes.
- **Track changes every 10 levels** — the specific creature pool that
  spawns for a given class shifts at each 10-level boundary.
- **Custom classes** inherit the creature type of their stat-growth
  parent class.
- **Pre-programmed interactions** between specific NPC types (innkeeper
  petting a dog, butcher feeding a dog, dog wagging tail at a merchant
  who feeds it). Phase 9-10 territory.
- **User-submitted interactions** via rmail mailbox. Anonymized by
  design (rmail does not remember senders). Sanitization is the
  privacy mechanism, not a content filter.

## Open Design Questions

- What counts as "creature type" — `creature_template.type` field
  values (BEAST/HUMANOID/ELEMENTAL/etc.)? Or a custom taxonomy?
- The 10-level "track shift" — does this mean the creature pool
  expands cumulatively, or a hard cutover?
- How does this interact with 127 (contextual-creature-spawns) and
  903 (regional-creature-spawn-themes)? They all touch creature
  selection.
- Friendly-combat AI: do these travelers use existing AzerothCore
  faction/aggro mechanics (assign a friendly faction, let smart-AI
  do the rest), or do they need bespoke behavior like the bots?
- User-submitted interaction format and validation — what's the
  Lua/data schema, and what stops malformed submissions?

## Related Issues

- 504 traveler-sit-with-player (the existing traveler framework)
- 503 dynamic-trainer-spawning (sibling traveler subsystem)
- 127 contextual-creature-spawns
- 903 regional-creature-spawn-themes (212 in old numbering)
- Phase 10 rmail issues (1001+) for the user-submission pipeline

## Viability Note

This idea is *expansive*. The selection algorithm alone (split creature
types across classes, recursive splitting when imbalanced) is its own
subsystem. Before committing, worth a smaller proof-of-concept: spawn
*one* friendly combat traveler per zone with a hardcoded creature pool
and verify the friendly-aggro mechanics work. If that's solid, the
class/level-track logic can layer on top.
