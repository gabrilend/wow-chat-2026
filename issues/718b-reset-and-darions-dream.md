# 718b - Reset a Death Knight, and Darion's Dream

## Status
- Created: 2026-10-13
- Phase: 7
- Parent: 718 (death knight sacrifice and open Acherus)
- Related: 617x (prestige: reborn with your buddies), 718a (allegiance
  after the story), `scripts/reset-dk-soul-trade` (the testing tool this
  grows from)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-13:

> also, gabrubre is still in Acherus. Can you make a "reset DK" command
> that will apply the various operations we've been doing to her to reset
> her completely? We should be able to do this on command, which is
> something we could "prestige" as as a max level death knight by talking
> to Darion Mograine and saying "How did we win our freedom?" and he says
> "I will teach you." then a dream state occurs where you relive your
> moments fighting for the Death Lord. Can we rename his name to that in
> all instances in the server files? Also can we make that be Darion
> Mograine's title now?

> the reset DK command shouldn't redo the given soul, but we should do
> that while we're testing the system. Also it shouldn't allow Sargobras
> to spawn, essentially resetting that DK to the point after talking to
> Sargobras, but before the Death Lord spawns. It should be just Sargobras
> at first, then he goes in visible and the death lord goes uninvisible
> and the player can select their first quest. that's the normal operating
> procedure, but when they talk to Darion Mograine and he runs the "reset
> dk" command on the player, and it's as if they had selected the "I do
> want to see the story" option and handed a soul to Sargobras to give to
> the Death Lord.

## Current Behavior

The only reset is `scripts/reset-dk-soul-trade` (718), a testing tool
run from the shell with the server up and the death knight logged out. It
undoes the whole trade: the soul goes home to its own account, the
ledger reads "owed", the story's quests, items, letter, spells, riding,
reputation, achievements and experience come off, level 55 and a new
death knight's money, talents reset at next login, buddies set aside, and
the death knight stands where new ones appear in Acherus. Sargobras then
offers the trade again.

On a fresh death knight today, Sargobras stands before the Lich King,
who withholds the first quest until the soul is paid; after the trade
Sargobras goes up in flame and stays hidden from that death knight
(`src/lua-basic/death-knight-souls.lua`).

Gabrubre (2026-10-13): soul given (Karson, now on the holding account
SOULS101, as designed), story not skipped, the first quest ("In Service
Of The Lich King") done. Her next step is Instructor Razuvious's "The
Emblazoned Runeblade", which gives the runeblade. She is not stuck.

## Intended Behavior

**The reset** puts a death knight back to the moment just after the soul
trade, with "I want to see the story" chosen: the soul stays given (the
hero stays on the holding account), the ledger reads "given", story not
skipped; everything the story gave comes off (as the testing tool takes
it off now); level 55, a new death knight's money, talents reset; it
stands in Acherus before the Lich King. Sargobras does not appear for it;
the Lich King is there and offers the first quest.

A **testing switch** also returns the soul and sets the ledger back to
"owed" (what `scripts/reset-dk-soul-trade` does now), so the trade itself
can be tried again.

**The order on a fresh death knight** stays: Sargobras alone at first;
once the soul is handed over, he becomes invisible and the Lich King
becomes visible, and offers the first quest.

**Darion's dream (the prestige).** A death knight at basic's level cap
talks to Darion Mograine in the Ebon Hold and chooses "How did we win our
freedom?". He answers "I will teach you." and the reset runs on them: a
dream in which they relive their service to the Death Lord, from the
first quest.

**The names.** The Lich King renamed "the Death Lord" (open question 1
asks exactly what is renamed, and Darion's title).

## Suggested Implementation Steps

1. Answer the open questions.
2. The reset as one routine, written once: a console command (`.dk reset
   <name> [--return-soul]`, Lua, runnable from `scripts/gm-command`),
   reusing the testing tool's lists (story quests, spells, skills,
   reputation, achievements). The shell tool becomes a caller of it, or
   is retired.
3. The Lich King hidden until the soul is paid, shown after (per death
   knight, as Sargobras is hidden now).
4. Darion's gossip option, shown at the level cap only; his line; the
   reset; the teleport into Acherus (the "dream").
5. The renaming (creature names and titles in the world database; the
   story's quest texts and lines if open question 1 says so).
6. Test on Gabrubre: reset, check her quests, items, level and where she
   stands; then the testing switch; then the dream from Darion.

## Open Questions

1. "Can we rename his name to that in all instances in the server files?
   Also can we make that be Darion Mograine's title now?" I read "his
   name" as the Lich King's, renamed "the Death Lord". Then which is
   Darion's new title (the line under his name, now "Highlord")? Or is it
   Darion who gets a new name? And "all instances": creature names only,
   or also every quest text and spoken line that says "Lich King"?
2. The dream: does it look like a dream (a screen effect, a different
   sky), or is it simply Acherus again?
3. What does the prestige give, besides reliving the story? (617x gives
   buddies a rebirth; does a death knight's prestige also re-pick its
   buddies?)
4. Does the reset keep the death knight's professions, gear bought since,
   money earned, and bags, or strip to a new death knight's?
