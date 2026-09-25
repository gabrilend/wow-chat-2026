# 617i - Buddy Battlegrounds

## Status
- Created: 2026-09-24
- Phase: 6
- Parent: 617
- Blocked by: 617c (login and party), 617e (travel to the owner's area)
- Priority: Medium

## Origin

Verbatim, 2026-09-24:

> For battlegrounds, every player who joins a battleground queue should
> have all their bots also join that queue. It's okay if they get split up
> and separated. If the player leaves the queue, then they all also leave.
> If they are in a battleground but their player is not, then they keep
> fighting in the battleground until it's done, then they walk to rejoin the
> player and continue adventuring. If the player invites them while they are
> in a battleground, they will leave the battleground and join their group
> instead.

## Current Behavior

Buddies do not exist yet. The bot module can queue random bots for
battlegrounds on its own (its battleground section in the bot config);
basic turns random bots off (155b), so on basic nothing queues bots.

## Intended Behavior

- When the owner joins a battleground queue, **every buddy** joins the same
  queue as individuals, not as the owner's group. They may land in
  different matches.
- When the owner leaves the queue, every buddy still queued leaves it.
- A buddy inside a battleground plays it to the end, even if the owner is
  not there, then leaves, travels to the owner's area on foot and resumes
  617e's adventuring.
- If the owner invites a buddy that is inside a battleground, it leaves the
  battleground at once and joins the owner's group.
- **Owner logs out**: buddies leave any queue and log out too (also from
  inside a match).
- **Owner queues with another player** as a group: both players' buddies
  join the queue; the players themselves are placed in the same match,
  as the stock group queue does.
- **Owner enters a dungeon while a buddy is in a battleground**: the buddy
  stays for now. In the dungeon draw (617c) it has lower priority than the
  owner's other buddies; if it is drawn anyway, it leaves the battleground
  and joins the dungeon party.
- **Deserter**: a buddy that leaves a match (pulled out by an invite or a
  dungeon draw) gets Deserter for **one third** of the stock duration, and
  can't queue until it ends.
- **Arenas**: when a player queues for an arena, buddies are drawn at
  random without replacement to fill the team (2v2: the player and one
  buddy; 3v3: two; 5v5: four). Two players queuing 3v3 must fill the
  third seat themselves with a buddy of either player: **in a group, the
  leader may invite any group member's buddies**, the one exception to
  buddies refusing other players' invitations (617c).
- Verbatim, 2026-09-24: "then they leave the queue and log out too." /
  "both their bots join the queues. Each player in the group is
  guaranteed to be put into the same battleground, of course." / "the
  buddy stays in the battleground tentatively. When the player enters a
  dungeon, their group is created right? well... the bot in the
  battleground is given lower priority than the other bots. If it is
  still chosen, then it will leave the battleground and join the dungeon
  group." / "A random buddy bot (chosen without replacement of course) is
  queued with the player, enough to fill their team. So for a 2v2, one
  player and one buddy bot, a 3v3, one player and two buddy bots, etc. If
  two players are in a group and queue for a 3v3, they can't join unless
  they fill their group to 3 with either one of their buddy bots (a player
  as the group leader can invite anyone in the group's buddy bots, which
  is different than the normal behavior where you can only invite to a
  group your own buddy bots)."

## Suggested Implementation Steps

1. Hook the owner's queue join and leave (the server's battleground queue
   handler) and mirror them for each buddy.
2. On battleground end for a buddy: set it to "return to owner's area"
   (617e's travel).
3. On owner invite while the buddy is in a battleground: leave, then accept.
4. Test with one owner and two buddies in the Warsong Gulch queue: join,
   leave, and a match where the owner is not placed.

## Related Issues

- **617** parent; **617c**, **617e**
- **155b** random bots off on basic

## Open Questions

- (Answered 2026-09-24) Other players' buddies fill the other side when
  those players queue too: "if the other players join the queue, then yes
  of course." The rules as given describe queue behavior.

- (Answered 2026-09-24) Deserter: "what if we made it last 1/3rd as long
  for buddies?" A buddy's Deserter lasts a third of the stock duration.
- (Answered 2026-09-24) The five edge cases, below in Intended Behavior.
