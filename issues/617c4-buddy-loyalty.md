# 617c4 - Buddy Loyalty

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617c
- Blocked by: 617c1
- Priority: Medium

## Current Behavior

**The override, written 2026-10-03, changed 2026-10-04 (the owner's
party first; full parties make room), syntax-checked, not yet built or
run.** Any invite into a full party (of a player or a buddy) takes out one
distance-seated buddy at random first, on the world thread, then goes to
the server as it arrived; with none, nobody is dropped. Every invite of a buddy from its owner's side (the owner, or
anyone in a group with the owner) by someone who may invite (no group
yet, or its leader or an assistant) is held and handed to the party
pass, which takes the buddy out of a match or any party it is in and
seats it in the inviter's group as invited by hand. A full group: it
stays where it is (a trace line). Someone in the owner's group who
isn't leader or assistant gets the server's own refusal.

Before the override:
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

**Invites override the distance grouping** (the owner, 2026-10-03, from
the live test: "We should be able to override the dynamic party system
by inviting bots to our group. In addition, we should be able to invite
party member's clan-members if we'd like, and they should stay in our
group. So, Sue invites Tracy, and Kyle is Tracy's buddy bot. Sue can
invite Kyle under the proposed system, and he'll adventure with both of
them."):
- an invite the loyalty rule allows (the owner, or someone in a group
  with the owner who may invite: its leader or an assistant) always
  works, even when the buddy is already in a party of its own clan's
  buddies (a far party) or in a battleground: it leaves that and joins
  the inviter's group, which holds its owner;
- **its owner's party comes first** (the owner, 2026-10-03: "It should
  never leave it's owners party when invited to a different party. The
  owner has priority. [...] Buddy-bots should only ever be in parties if
  their player-partner is in that party."): a buddy is only ever invited
  into a group its owner is in, so an invite never takes it out of its
  owner's party; one already in the inviter's group just becomes
  invited by hand;
- **a full party makes room** (the owner, 2026-10-03: "if there's 5
  players in a party and another player or buddy-bot is invited, we
  should remove one of the dynamically added buddy-bots at random to make
  space. If there are none, then we know that everyone in the party was
  manually invited, and we shouldn't drop anyone."): any invite (of a
  player or a buddy) into a full party first takes out one buddy the
  distance grouping seated, at random; with none, nobody is dropped and
  the server answers "full" as usual;
- it joins as invited by hand: the distance grouping never takes it out
  again (617c2's rule for hand-invited buddies), in towns too;
- it is seated directly, the way a buddy invited out of a battleground
  is (617i), so the bot module's own invitation steps (its permission
  check against a stranger, its "Hello", its strategy reset) don't run.

## Suggested Implementation Steps

(The override, 2026-10-03:) the loyalty check holds every allowed invite
of a buddy and hands it to the party pass's pull (`buddies_party.cpp`,
the battleground pull generalised: leave a match first only when in
one), which removes it from a far party and adds it to the inviter's.
An invite of anyone into a full party with a distance-seated buddy is
held too; on the world's thread the pass takes out one such buddy at
random and then hands the held invite to the server's own invite
handling, as if it had just arrived.

(The original plan, not followed: the request hook made a patch
unnecessary.)

1. A bot-module patch in the accept-invitation path, marker-bracketed like
   B025, asking whether the inviter is the buddy's owner (or leads a group
   holding the owner).
2. `scripts/test-source-patches`, `scripts/test-patched-syntax`; in game.

## Related Issues

- **617c** parent; **617a5** (buddies deaf to bot chat commands)
