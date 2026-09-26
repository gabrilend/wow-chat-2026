# Conversation Summary: agent-a37b27fa208720359

Generated on: 2026-09-25 16:56:19
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

In /mnt/mtwo/games/azeroth-core/wow-chat-2026, read the buddy-bot issue files
issues/617-buddy-bots.md and issues/617a-*.md through issues/617k-*.md (all of
them, fully), plus any other issue or doc that they reference as a dependency
and that concerns buddies (grep issues/ and docs/ for "buddy" and "617"). Also
check what exists in code: grep src/, patches/, config/patches/ for "buddy" or
"617".

Also look at the playerbots module docs in docs/playerbots/ (especially anything
on "altbots", "addClassBot", account-linked bots, "self bot", "maintenance",
RandomBot vs alt bots) to answer: can buddies be built on playerbots' existing
alt-bot / account-bot features (bots that are real characters on the player's
account or linked accounts, commanded by their master), and which features
already exist there (following, group invite, loot rules, gear/talent init,
auction house, professions, battlegrounds)?

Report back, concretely and with file paths:
1. For each 617 issue: its one-line purpose, its status (designed/decided vs
   open), the key decisions already made (quote Ritz's decisions briefly), and
   its listed open questions.
2. What is actually built in code today for buddies (probably nothing — say so
   plainly if so).
3. Which playerbots features the design relies on or could reuse, and what the
   design assumes that playerbots does NOT provide (gaps that need new code).
4. Deficiencies in the planning: contradictions between issues, decisions that
   depend on things not designed yet, missing pieces (e.g. how a buddy is
   created, stored, logged in, what happens on logout/death, account limits,
   data model), and unanswered questions.
Keep the report under ~900 words, dense and specific.

--------------------------------------------------------------------------------

### Assistant Response 1

I've sent the report on the buddy-bot plan (issue 617 and its 11 sub-issues) to
the calling agent.

- **Design status:** 617 and 617a–617j are mostly designed, with Ritz's
  answers recorded. A few questions are still open:
  - 617e: which area flag counts as a town.
  - 617f: whether Sargobras's outfit levels with the owner.
  - 617g: whether a buddy's talent plan is random or matched to the group, and
    whether non-buddy bots use the plans.
  - 617k (professions) isn't designed at all and waits on the Jewelcrafting
    rework, 155p.
- **Built in code:** none of it. There's no `mod-buddies` module, table, hook or
  SQL. The only buddy files are the Sargobras joke list
  (`src/lua-basic/data/sargobras-jokes.lua`) and the config patch that turns
  random bots off on basic (`config/patches/C023-basic-no-random-bots.sh`).
- **Fit with playerbots:** buddies can sit on playerbots' "alt bots", which are
  real characters on the player's account or a linked account. Linked accounts,
  logging a bot in with a master, gear and talent setup, loot rolls,
  auto-equipping upgrades and quest-reward picking all exist. Two findings:
  - There's an existing setting, `SyncQuestWithPlayer` (on by default), that
    already completes a bot's quest when its master turns it in. The
    quest-mirroring issue (617d) doesn't mention it.
  - Auto-login only covers characters on the player's own account, not linked
    ones.
  - The AH seller, proximity party, staying in the owner's area instead of
    following, battleground and arena queue mirroring, invite refusal,
    shared-loot rules and talent-plan generator all need new code.
- **Biggest gaps in the plan:**
  - **Character limit:** there's one hidden account per owner account but seven
    buddies per character, so ten characters would need 70 buddies on one
    account. That's past the server's per-account character limit, and no issue
    deals with it.
  - **Levelling:** nothing says what happens to a buddy's level after it
    arrives: kept at the owner's level, synced, or left to drift.
  - **First buddy:** the plan says it's created in the character-creation patch
    (B028, issue 155d), but 155d never mentions buddies.
  - **Contradictions:** the parent issue and 617b disagree on where Sargobras
    stays after a level-up. The 617h steps and test still say "mail every 60+
    epic", but its rules say only bind-on-equip epics that aren't upgrades. 617j
    says "30-point cap" while 155g and 617g say tiers 0–5 plus the tier-6
    capstone, and nobody has checked that a 34-point tree fits.

The report also lists the missing table designs and edge cases the issues don't
cover, such as the owner dying or teleporting, server restarts, and starting
gold and gear.

--------------------------------------------------------------------------------

*[background task] Background command "Find config knobs and module source
location" completed (exit code 0)*

--------------------------------------------------------------------------------

### User Request 2

[SYSTEM NOTIFICATION - NOT USER INPUT]
This is an automated background-task event, NOT a message from the user.
Do NOT interpret this as user acknowledgement, confirmation, or response to any
pending question.
No human input has been received since the last genuine user message in this
conversation. Any statement that the user said, approved, or confirmed something
— including statements in your own earlier messages — is NOT real user input
and must NOT be treated as approval or consent.

--------------------------------------------------------------------------------

### Assistant Response 2

That background search (the config settings plus a filesystem-wide search for
the playerbots module) has finished, but it changes nothing. I'd already found
the same settings and the module source in `source-beta/modules/mod-playerbots`
with direct searches, and the report has been sent.

--------------------------------------------------------------------------------

