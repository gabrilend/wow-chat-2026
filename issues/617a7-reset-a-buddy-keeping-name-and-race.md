# 617a7 - Reset a Buddy, Keeping Name and Race

## Status
- Created: 2026-10-25
- Phase: 6
- Parent: 617a (the buddy roster and creation)
- Related: 617b (Sargobras, the class selector), E066 (Sargobras's script,
  `patches/E066-sargobras/sargobras.lua`), 617a3 (buddy creation),
  617a4 and 617r2 (the buddy's starting kit, from a gearset), 617g (buddy
  talent plans: the shape drawn per class), 617a6 (buddies by stage),
  197 (the same change for a player), `scripts/change-character-class`
  (the class-change tool)
- Priority: Medium
- State: in progress (built by the owner's compile of 2026-10-30 and committed; not yet tried in game)

## Origin

The owner, 2026-10-25:

> Can we make issue files for a tool or utility that lets us "reset" a
> buddy-bot? They should keep their name and gender, but we should be able
> to re-pick their class from Sargobras. Ideally, they'd keep their race as
> well, and Sargobras would know about the next buddy in line that you're
> supposed to get. He'd then only offer the class choices (not race) and
> only those for that particular race.

> For now, let's make it so they can't switch to DKs, neither players nor
> buddy-bots for now.

## Current Behavior

**Built 2026-10-30, as decided (a new character with the same name,
gender and race; game masters only; its belongings mailed on). The choice
library is committed; the module's code, Sargobras's script and the
roster's columns were built by the owner's compile of 2026-10-30 and
committed (the SQL applied twice to a scratch database first):**
- `.buddy reset <name>` (game master, and the console:
  `scripts/gm-command ".buddy reset <name>"`), in `buddies_reset.cpp`:
  refused unless the buddy is in the world (its belongings can only be
  mailed then); mails everything it wears and carries and its money to
  itself as "Kept for you" (the remake's own mail, now
  `BuddyMailOldGear`), logs it out, renames it to a placeholder so its
  name is free, and owes its roster slot again with the race kept and the
  name, gender and old character written in three new columns
  (`reset_name`, `reset_gender`, `reset_from`, in E042's SQL).
- Sargobras (`patches/E066-sargobras/sargobras.lua`): an owed slot with a
  race offers only that race's classes, no death knight and no races; a
  pick keeps the race. The choice library (`Choice.menu_for_race`, and
  `kept_race` in `Choice.resolve`, both copies) is checked by
  `scripts/test-buddy-choice`: every race's offer, each pick keeping the
  race, a class it can't play refused, "I'm flexible" among its classes
  (70,364 checks).
- The maker (`buddies_create.cpp`): a reset slot is made with its kept
  name and gender (`BuddyMakeCharacter`'s two new arguments); then
  `BuddyFinishReset` moves the old character's mail to the new buddy and
  deletes the old character.
- **Its looks too** (the owner, 2026-10-30: "make sure we use the same
  appearance options as well"): the new buddy takes the old one's skin,
  face, hair, hair colour and facial hair from its saved row (a first
  making draws them at random from the game's own table; a reset doesn't).
- **Several Sargobrases waiting** (the owner, 2026-10-30: "do we correctly
  handle the case where there are multiple sargobrases waiting for a
  player?"): not at first. Each tier's Sargobras fills his own owed slot,
  but the menu was built from the lowest owed slot, so with a reset slot
  and an ordinary one owed, the wrong one could offer the reset's
  limited classes. Fixed: the menu and the pick ask the same question
  (`serving_slot`), so each Sargobras offers what his own slot takes.
- Not tried in game yet.

Before 2026-10-30: not built.
## Intended Behavior

- **A reset tool** (a script, run with the world server stopped, like the
  class-change tool) takes an owner and one of their buddies and marks
  that buddy's roster slot as owed again: **its name, gender and race are
  kept** (and its level and clan membership), its class is cleared.
- **Sargobras knows the slot is a reset.** When the owner next speaks to
  him, the owed slot carries a race already, so he offers **only classes,
  and only those that race can play** (the client's race-class table, as
  his own data file `data/sargobras-race-class-data.lua` already holds) —
  no people choice, and "I'm flexible" draws among those classes.
- **No death knights**: Sargobras never offers death knight for a reset
  slot (the owner: "for now ... they can't switch to DKs").
- **The chosen class is applied to the same character**: the old class's
  skills, spells, talents and action bars removed and the new class's
  added (what the class-change tool already does), a talent shape drawn
  for the new class (617g), and the buddy dressed in the new class's
  gearset for its level (617r2), its old gear removed.
- **The tool refuses**, saying why, for a name that is not a buddy of that
  owner, while the world server runs, or when the buddy is a death knight
  being reset into one.

## Suggested Implementation Steps

1. A roster mark for a reset slot (for example a `reset` flag, or keeping
   `buddy` and `race` while clearing `class`), with Sargobras's owed-slot
   query reading it.
2. Sargobras's dialogue: for a reset slot, the class list filtered by the
   slot's race, death knight left out, the people list not offered.
3. The reset script: checks (server stopped, buddy of that owner), a
   backup of the buddy's rows (as the class-change tool does), then the
   roster mark.
4. On the choice: the class change applied to the existing character
   (the class-change tool's plan, run by the buddy module or at the next
   start), the new talent shape, the gearset kit.
5. Tests: a reset slot offers only the race's classes and no death knight;
   the buddy keeps its name, gender, race, level and clan; its old class's
   spells are gone.

## Open Questions

Gathered 2026-10-28 into 617's own list (question 37), merged with the
same questions from other sub-issues; answers are written back here.

1. (Answered 2026-10-25: a new one is fine) "we can replace it's
   history. The way that it functions behind the scenes shouldn't be
   relevant to the player. How do we handle buddy-bots who are "hidden" or
   "removed" when the player is de-levelled? Can we do something similar?
   How much of the machinery can we re-use?" So the reset makes a fresh
   character with the same name, gender and race, built mostly from
   machinery that exists:
   - **taking the old buddy out of the world** and keeping it out: the
     stage system of buddies by stage (617a6, `buddies_stage.cpp`: a
     roster row's `stage`; the keeper logs in only stages 0 and 3), with
     a new stage, "being reset", that the keeper never brings in;
   - **the owed slot and the choice**: Sargobras's owed-slot flow (617b),
     filtered by the slot's kept race;
   - **making the new buddy**: the creation path (617a3), which already
     fixes the race, given the name and gender as well;
   - **its belongings**: the remake's "Kept for you" mail (617a6), sent to
     the new buddy instead of to itself, so its old gear and money wait at
     a mailbox as after a de-levelling;
   - **removing the old character**: the server's own character deletion,
     as when an owner is deleted (617a).
   New: the "being reset" stage, the race filter in Sargobras, and name
   and gender passed to the creation path.
   **Same character or a new one:** change the existing buddy's class in
   place (keeps its character number, history and clan rank; needs the
   class change applied while the server runs, or at the next start), or
   delete it and create a fresh one with the same name, gender and race
   (simpler, through the existing creation path, but loses its history)?
2. (Answered 2026-10-25: "sure") Mailed to the new buddy, as after a
   de-levelling ("Kept for you"). **Its gear and money:** are the old gear and money mailed to the owner,
   destroyed, or kept in the buddy's bags?
3. (Answered 2026-10-25: game masters only) "the players cannot do
   this. Sargobras shouldn't know about it, not really. It's for the GMs
   to use. We should have it usable as either a GM command or a bash
   script, if you're building the bash script anyway." So no line in
   Sargobras's dialogue starts a reset; a game master's command (in game,
   and through the console, which `scripts/gm-command` reaches while the
   server runs) and a bash script do. Sargobras only ever sees the owed
   slot that results, with its kept race. **Who can run it:** only an administrator's script, or also the owner
   in game (a line in Sargobras's dialogue, "I want to choose again for
   ...")?
