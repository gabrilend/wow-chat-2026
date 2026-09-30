# 617c3 - The Dungeon Draw

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617c
- Blocked by: 617c2
- Priority: Medium

## Current Behavior

**Built 2026-09-29, not yet compiled or tried in game** (owner: "we should
ensure that's working too"): `buddies_party.cpp`, "the dungeon draw". On
the owner's arrival in a five-player dungeon (the map-change hook; the
draw itself 1.5 s later in the world pass, after every map's update),
the party's empty seats up to five are filled from the bag
(`buddy_draw`, characters database, in `04-buddy-roster`): drawn at
random, marked had-a-turn; when too few are left the bag refills and the
draw goes on, skipping those just drawn. Buddies the distance rule had
seated make way; hand-invited ones keep their seats. The drawn join the
Two or more players grouped, a raid, a battleground or a dungeon-finder
group: left alone. On the owner's return to the open world, buddies still
in an instance come out beside them. Buddies in battlegrounds are simply
not drawn (617i isn't built, so none are). Inside, they fight by the bot
module's own rules until the kraken runs in game.

## Intended Behavior

617c's dungeon party, unchanged: on entering a dungeon, four buddies drawn
at random without replacement from a bag that refills when everyone has had
a turn (the `buddy_draw` table, 617a's data model), brought into the
instance; only empty slots filled when the owner is already in a party; no
auto-fill when two or more players are grouped; a buddy in a battleground
drawn last (617i).

## Suggested Implementation Steps

1. The `buddy_draw` table (characters database, an install step).
2. A dungeon-entry hook: draw, re-form the group, bring the drawn in.
3. In game: three runs give every buddy a turn before anyone repeats.

## Related Issues

- **617c** parent; **617c2**; **617i** battlegrounds
