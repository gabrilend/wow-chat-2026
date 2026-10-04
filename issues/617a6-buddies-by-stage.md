# 617a6 - Buddies by Stage: Only the Owner's Current Stage Comes Along

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617a
- Blocked by: 617a3 (buddy creation), 617c1 (logins)
- Priority: Medium

## Origin

The owner, 2026-10-03: "Can you tell me what happens if we level a
character DOWN while they still have buddy-bots? Can we store them, and
ensure that only the correct ones spawn, and when Sargobras shows up, he
says 'Oh it looks like you already have a buddy-bot for this stage of
your journey. Here let me summon them...' and then re-enables them?"

## Current Behavior

Rebuilt 2026-10-03/04 to the owner's answers (below), compiles
(syntax-checked); the SQL was run twice on a scratch copy of the
characters database; not yet tested in game.

- The roster rows carry `stage` (0 with its owner, 1 waiting, 4
  recording, 3 to be made again).
- At every owner login and level change (`buddies_stage.cpp`):
  - a buddy whose slot is above the owner's level leaves the world (the
    owner's bot manager logs it out), is recorded 5 seconds after it is
    fully gone, and waits;
  - a waiting buddy is due to be made again once the owner reaches its
    slot's level;
  - a buddy of a slot the owner keeps, above the owner's level, leaves the
    world, is recorded, and is then logged straight back in to be made
    again.
- Made again, at its login (`Remake`), at the owner's level: what it
  wears and carries, bags included, and its money are mailed to itself
  ("Kept for you", kept 900 days), its class lessons and quest spells forgotten, its
  level set, talents reset (re-spent by the talent spender; a hunter gets
  a new pet), lessons, starting kit and gems given again. If the owner has
  climbed back to its level by then, it is kept as it is.
- At a mailbox (`buddies_town.cpp`) a "Kept for you" mail gives up only
  the items the buddy can use now, and only such items send it to the
  mailbox.
- The keeper (`buddies_login.cpp`) brings in stages 0 and 3 only.
  Sargobras has no part in it.
- Left alone by the remake: bank, professions, reputation, quests,
  keyring.

## Intended Behavior

(Rewritten twice on 2026-10-03 from the owner's answers; the first design
had Sargobras bring stored buddies back and reset them to how they were
first made, the second let a waiting buddy come back unchanged at its own
level.)

- **Higher slots wait**: a buddy whose slot's level is above the owner's
  new level leaves the world and waits until the owner reaches the
  slot's level; then it is made again at the owner's level, like every
  other (the owner: "the more I think about it, the more I think we should
  just treat them all the same, and re-initialize the level 35 guy too
  when the player-partner reaches level 30. At level 30.").
- **Kept slots are made again**: a buddy of a slot the owner still has,
  if above the owner's new level, is made again at the owner's level, as
  a new buddy would be made ("Everyone gets re-instantiated to the
  highest level tier that they could spawn as.").
- **Its old gear by mail**: what it wore and carried when made again is
  mailed to it (the owner: "Can we maybe mail them their old gear? It's
  okay if they forget abilities."), with its money; at a mailbox it takes
  out only what it can use at its level, so the rest waits in the mail
  until it has levelled into it.
- **Recorded first**: either way, the buddy as it was (level, gear,
  spells, talents) is kept, for the later level-scaling.
- **Only the right ones**: at any time the owner's online buddies are
  those of the slots at or below its level, none above its level.

## Suggested Implementation Steps

1. **The roster** (`04-buddy-roster.apply.sql`, install step E042): a
   `stage` column on each row, added to tables made before it as the
   greeting column was: 0 with its owner; 1 waiting; 4 recording (a kept
   slot's buddy above the owner); 3 to be made again at its next login.
2. **The record** (same file): `buddy_stage_record` (level, experience,
   money, when), `buddy_stage_item` (every item it carries or wears: its
   own id, the bag it sits in, slot, entry, count, enchantments and gems,
   random suffix, durability), `buddy_stage_spell`, `buddy_stage_talent`.
   Written in one transaction a few seconds after the buddy has logged
   out, so its logout save is in first; a newer record replaces an older.
3. **The stage check** (`buddies_stage.cpp`), at every owner login and
   level change, per made buddy: with its owner and its slot above the
   owner: out and waiting; with its owner, slot kept, above the owner:
   out and recording; waiting and the owner at or above the slot's level:
   to be made again (it was recorded when it went to wait). Slot levels are the ones the slots are owed at (slot 1 at
   level 1, so the first slot is never a higher slot).
4. **The world pass**: each record, once its buddy is fully out; a
   recording buddy then becomes "to be made again" (in that order on the
   database queue).
5. **The login and the keeper** (`buddies_login.cpp`) bring in stages 0
   and 3 only.
6. **The remake** (`buddies_stage.cpp`, at the login of a stage-3 buddy):
   what it wears and carries, bags included, and its money are mailed to
   it (several mails of at most 12 items, subject "Kept for you", sent by
   itself), then it is made as buddy creation makes a buddy (lessons up
   to the level, starting kit, gems); its stage then 0.
7. **The mailbox** (`buddies_town.cpp`, the mail errand): from a "Kept
   for you" mail only the items it can use now are taken; the mail stays
   until it is empty.

## Open Questions

- (Answered 2026-10-03) While stored: "keep their old level and gear and
  such, but when you talk to Sargobras he 'reinitializes them' to their
  level 40 or 50 or 20 or whatever state - whenever they were first
  brought to you." So the re-enabling resets the buddy to its first
  appearance: the level of its slot when it was made, its starting kit
  and lessons for that level (617a4, 617n) and its talent plan's points
  for it; the roster keeps what it needs for that (the level it was made
  at).
- (Answered 2026-10-03) How the owner got lower: "we will add mechanics
  for that later. For now, let's say it doesn't matter."
- (Added 2026-10-03) Why the stored state is kept: "I'm thinking of adding
  a system that scales your level up or down to play with higher or lower
  level characters. City of Heroes has a system like that. But that's
  much later work, and in that case we *wouldn't* want to re-instantiate
  the buddy-bots, hence why we're recording their equipment and such at
  the time of the player character's de-levelling." So storing a buddy
  records its level, gear, spells and talents at that moment; Sargobras's
  re-enabling (an owner levelling up again) resets it to how it was first
  made, and the later level-scaling will restore the recorded state
  instead.
- (Answered 2026-10-03, changes the design; not yet rebuilt) A buddy made
  above its slot's level: built as "reset, never above the owner's level".
  The owner: "I don't think so? Basically if the owner is 35 and the
  buddy bot is 35, then the owner gets dropped to level 20, then only
  their first 3 buddy-bots would stick around. The level 35 buddy-bot
  would hang out and wait until they got to level 35, and then they would
  start spawning again. I guess we don't need Sargobras to show up, just
  wait until the owner is the same level as the buddy-bot." So a stored
  buddy comes back by itself, as it is, once the owner's level reaches
  the buddy's own level; no Sargobras line and no reset on that path.
- (Answered 2026-10-03, later the same day) Higher slots: "treat them all
  the same, and re-initialize the level 35 guy too when the
  player-partner reaches level 30. At level 30." Old gear: "Can we maybe
  mail them their old gear? It's okay if they forget abilities."
- (Answered 2026-10-04) How long the old-gear mail lasts (the server's
  rule for mail from a player is 30 days): "No, we should change the
  duration to be 900 days." Built: the "Kept for you" mails are sent with
  a 900-day keep.
- (Answered 2026-10-03) Does Sargobras's re-enabling and the reset to the
  first-made state still happen anywhere? "replace both I think." And the
  slots the owner keeps, with buddies above its level? "only the higher
  slots wait. Everyone gets re-instantiated to the highest level tier
  that they could spawn as. So in your example the first three slots
  would get re-instantiated at level 20." Built with "the highest level
  tier they could spawn as" read as the owner's level (a buddy is made at
  its owner's level).

## Related Issues

- **617a** parent; blocked by **617a3**, **617b**, **617c1**
