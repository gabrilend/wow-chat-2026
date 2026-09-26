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
  and the clan start together. The owner types it into a pop-up text box
  opened from his conversation menu (the box the stock client shows for a
  conversation option that asks for a code), so no addon is needed. If
  the name is taken (guild names are unique on the server), he asks again
  with a joke until the owner picks a free one.
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
- (Answered 2026-09-25) The name is typed into a pop-up text box from a
  conversation option with Sargobras (the stock client's coded gossip box;
  the Lua engine receives the text). No addon needed.
- (Answered 2026-09-25) The owner can't leave the clan guild, and guild
  banks are disabled (Ritz: "guild banks are disabled and you can't leave
  your guild"). So joining a friend's guild is not possible on basic.
- (Answered 2026-09-25) A taken name: Sargobras asks again, with a joke
  about it, until the owner types a free one (as the stock game treats
  taken character names).
- (Answered 2026-09-25) Other players are never invited: a clan guild is
  one owner and their buddies; friends talk by whisper or custom channels.
- **Conflict**: Ritz, 2026-09-25: "In-game player guilds should exist
  though. They're useful abstractions!" But the stock game allows one
  guild per character, and an owner can't leave the clan guild, so no
  owner could ever join a player guild. Which gives way: clan chat moves
  off the guild (a private chat channel per clan, so the guild slot stays
  free for player guilds); the owner may leave the clan guild for a player
  guild (the buddies stay in theirs); or a source patch lets a character
  hold two guilds? (A server-wide layer above guilds is 1007.)
  Ritz, 2026-09-25: "I said I wanted player guilds to exist, I didn't
  intend to imply that they should be ordinary. Check out rao-chat."
  (`/mnt/mtwo/programs/rao-chat`, Ritz's decentralised chat: a room is a
  label, a shared token and its members' addresses; holding the token is
  being invited; rooms nest in a tree, each child room its own invitation,
  "tiers of trust"; labels belong to the reader; you choose who hears you,
  never who hears anyone else.) Proposed reading, to confirm: the stock
  guild slot stays the clan guild, and **player guilds are rao-chat-style
  rooms**, a layer beside the stock guild, not in it. A character may be
  in any number; a guild's sub-groups (officers, a raid team) are child
  rooms; anyone may start one; the same rooms reach across servers (1007).
