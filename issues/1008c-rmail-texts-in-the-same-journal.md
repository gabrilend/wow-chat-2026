# 1008c - rmail Texts in the Same Journal

## Status
- Created: 2026-10-26
- Parent: Issue 1008 (journals-of-what-each-player-saw)
- Phase: 10
- **Blocked by:** 1008a

## Overview

The owner, 2026-10-26: "Any text message we send, we also possess as
text directory contents, hashed to the user of course."

Text the project sends a player outside the game client (rmail replies
to account requests, 1003; game mail forwarded by the bridge, 1004; the
narrator, 910) is kept as files in that player's journal folder, each
locked to their public key, so the journal holds everything the server
ever said to them, in and out of the game.

## Current Behavior

The rmail services are designed (1001-1006) but not built; nothing keeps
a copy of what they send.

## Intended Behavior

Every rmail service's outgoing message to a player with a journal key is
also written as
`journals/rmail/<account id>/<time>-<service>.journal`, a one-line
journal file in 1008a's format (kind `rmail`, sender the service's
address). The copy is made by the same step that puts the message in the
outbox, so a message sent is a message kept.

The rmail side is Lua, so it uses `scripts/lib/journal-seal.lua`
directly, with the public key read from `acore_auth.account_journal_key`.

## Suggested Implementation Steps

1. A small "send and keep" step in the rmail tools that every service
   calls instead of writing to the outbox itself.
2. Test: a reply sent by 1003's account creation is in the outbox and
   in the journal folder, and opens with the new account's password.

## Open Questions

1. ~~Which account an rmail address belongs to~~. The owner,
   2026-10-28: "maybe in their account management page they can change
   the rmail secret key or whatever?" So each account keeps the rmail
   contact it is tied to (first: the address that asked for the account,
   1003), and the player can change it on an account management page.
   That page is not designed yet; it belongs with the account form on the
   connection page (1008f question 3).

## Related
- `issues/1003-rmail-account-creation.md`, `issues/1004-rmail-ingame-bridge.md`
- `issues/910-wandering-narrator-system.md`
