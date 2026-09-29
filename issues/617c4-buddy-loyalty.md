# 617c4 - Buddy Loyalty

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617c
- Blocked by: 617c1
- Priority: Medium

## Current Behavior

**Built 2026-09-28; compiles, not yet run.** No bot-module patch was
needed: `modules/mod-buddies/src/buddies_loyalty.cpp` reads each player's
invite request before the server handles it (the incoming-request hook the
clan lock uses). When the invited character is a buddy (on a companion
account, with a roster row), the request goes through only if the inviter
is its owner or leads a group holding the owner; otherwise it is dropped
and the buddy whispers the inviter "Thanks, but I stay with my clan." (The
owner, 2026-09-28, on the first wording, "I don't follow other masters":
"they aren't masters, they're clanmates, and there wouldn't be a hierarchy
except only the player can do certain things so we have them do those
things, like decide where to go and such. Otherwise they are their own
masters, owing alliegance to a clan as their family. You don't choose
family, but it is all you got. It's all that the game gives you, at
least.")
The buddies' own grouping (617c2) adds members through the server
directly, so it is untouched. Not covered: an invitation to a buddy that is
offline (the server refuses those anyway), and chat commands to the bot
(617a5).

## Intended Behavior

617c's loyalty rule, unchanged: a buddy declines every group invitation
except its owner's, saying so ("sorry, I don't follow other masters"); a
group leader may invite the buddies of any player in that group (617i's
arenas).

## Suggested Implementation Steps

1. A bot-module patch in the accept-invitation path, marker-bracketed like
   B025, asking whether the inviter is the buddy's owner (or leads a group
   holding the owner).
2. `scripts/test-source-patches`, `scripts/test-patched-syntax`; in game.

## Related Issues

- **617c** parent; **617a5** (buddies deaf to bot chat commands)
