# 920e - Talking from a Phone

## Status
- Created: 2026-10-20
- Phase: 9
- Parent: 920 (legendary friends in every friends list)
- Blocked by: 920c (the conversation store and the reply path)
- Related: 1001-1006 (rmail, the project's messages between a player's own
  machine and the server; 1004 its in-game bridge)
- Priority: Parked (with its parent, 920: the legends are Blizzard's characters; see 920's "Parked")

## Current Behavior

Not started. Nothing outside the game can reach the server's chat layer.

## Intended Behavior

The owner: "we can make a phone app so they could talk to them IRL too,
meaning you could live with your chatbot friend."

A small phone app where a player signs in with their game account, picks
one of their characters, and talks to that character's legends. It writes
into and reads from the same conversation store as the game (920c), so a
conversation started on the phone goes on in the game's window (920d) and
the other way round; Broxigar remembers the morning's talk when the
player logs in at night.

The phone reaches the server through one small service beside the
worldserver, which signs the player in against the auth database, passes
messages to the same model runner (916d) with the same sheets and rules,
and writes to the store. When the worldserver is down, the phone still
works, since the service and the model runner don't need it.

## Suggested Implementation Steps

1. Decide the route (open question 1).
2. The service: sign-in, list of characters and their legends, send a
   message, read history; no access to anything else in the databases.
3. The app's screens: sign in, a list of legends, a conversation.
4. A test that sends from the "phone" (a script standing in for it) and
   reads the same message from the game's store.

## Open Questions

1. **Through rmail or its own service?** rmail (1001-1006) already carries
   messages between a player's machine and the server, with addresses and
   accounts; the legends could be rmail addresses. Or a small service of
   their own, made for back-and-forth chat. Which?
2. **Which phone?** Android, iPhone, or a web page that works on either
   (simplest, no app store)?
3. **Out in the world,** should a legend know it is talking to the
   player, not the character ("you could live with your chatbot friend")?
