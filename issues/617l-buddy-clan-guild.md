# 617l - A Guild for Each Clan

## Status
- Created: 2026-09-25
- Phase: 6
- Parent: 617
- Blocked by: 617a (roster: who is in a clan)
- Related: 617k (professions: buddies hand out crafts and consumables to the
  clan), 617j (the clan's shared gear pool), 916 (buddies' in-character chat)
- Priority: Medium

## Origin

Verbatim, 2026-09-25, while designing buddy professions:

> Each clan gets it's own guild auto-created and named by the player, and
> they will use it to chat with each other.

("Clan": a character and its buddies, as in 617j.)

## Current Behavior

Not designed beyond the line above. Nothing is built. The stock server
creates a guild from a charter signed by other players, or by a GM command;
a character belongs to at most one guild.

## Intended Behavior

- Every owner character gets a guild of its own, holding the owner and its
  buddies, created automatically; the owner chooses its name. Sargobras
  asks for it when the first buddy is made (Ritz, 2026-09-25), so the guild
  and the clan start together.
- The clan uses guild chat to talk among themselves (buddies' lines are
  in-character once the chat module, 916, reaches basic).
- The owner can't leave it; guild banks are disabled on basic (Ritz,
  2026-09-25). The stock server has no setting to switch guild banks off
  (read 2026-09-25 in worldserver.conf.dist), so that takes a source patch
  or a data change (e.g. no guild bank vendor spawns); to design.

## Suggested Implementation Steps

1. Settle the open questions below with Ritz.
2. Server side, in the buddy module (617a): create the guild through the
   core's guild API (no charter) when the owner names it, add each buddy
   as it is created, remove buddies with their owner.

## Open Questions

- (Answered 2026-09-25) Sargobras asks the owner for the guild's name when
  the first buddy is created, so the guild begins with the clan.
- How is the name typed: a pop-up text box from Sargobras's conversation,
  or the owner saying it in chat to him?
- (Answered 2026-09-25) The owner can't leave the clan guild, and guild
  banks are disabled (Ritz: "guild banks are disabled and you can't leave
  your guild"). So joining a friend's guild is not possible on basic.
- Guild names must be unique on the server: what happens when the chosen
  name is taken?
- Are other players ever invited into a clan guild?
