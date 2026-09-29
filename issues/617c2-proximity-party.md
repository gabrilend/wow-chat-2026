# 617c2 - The Proximity Party

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617c
- Blocked by: 617c1
- Priority: High

## Current Behavior

**2026-09-29:** a buddy is only ever taken out of its owner's party (past
75 yards, or in a town) if the pass itself seated it; one the owner
invited by hand stays (owner: "buddies shouldn't leave manually-invited
groups"). The seated set is kept in memory, so after a restart every
buddy still in the party counts as invited by hand. The starting valleys
count as open country, not towns, though seven of eight carry the
client's town flag (`buddies_roam_ground.cpp`).

**Built 2026-09-27; compile-checked against the last beta build's
settings, not yet run** (`modules/mod-buddies/src/buddies_party.cpp`,
`buddies_xp.cpp`; source patch `patches/B037-playerbots-invite-alts-on-login.sh`;
config patches `C029-basic-buddies-keep-own-parties.sh`,
`C030-basic-buddies-no-login-invite.sh`).
Every 5 seconds, for each online owner out of instances and towns:
- a buddy in the owner's group past 75 yards leaves it; a buddy in a far
  party (a group of only this owner's buddies) within 74 of the owner
  leaves it, and so does one more than 74 yards from every other member
  of its far party; the server disbands a group left with one member.
  A far-party buddy that could join the owner's party (within 60, the
  party with room) therefore leaves its far party and joins the owner's
  in the same pass (owner, 2026-09-27: "or when it could join the
  player's party");
- ungrouped buddies within 60, nearest first, join the owner's party while
  it has fewer than five (the owner leads a new one if ungrouped; a raid
  the owner made with other players is never joined);
- each ungrouped buddy past 74 (lowest guid first) joins a far party with
  room one of whose members is within 70 yards of it; failing that it
  pairs up with another loose far buddy within 70 in a new party it leads;
  a far buddy with nobody within 70 waits;
- two far parties merge when a member of one is within 70 yards of a
  member of the other and together they fit in five: the smaller one's
  members move into the larger; the emptied party disbands itself and is
  not touched after (members are asked for their group, not the old
  group);
- a raid made only of the owner and their own buddies is still broken up
  (it no longer comes from the login invite; an install without C030, or
  an owner who invited them all by hand).
**The group bonus counts humans only** (`buddies_xp.cpp`, the server's
kill-reward hook `OnPlayerRewardKillRewarder`, which lets a module change
each member's rate): the rate is scaled by the bonus for the human players
near the kill over the bonus for everyone near it, "near" counted as the
server counts it (alive, the killer or within the group reward distance of
the victim, `KillRewarder`). Stock in battlegrounds (no bonus there) and in
raid dungeons with a raid group (a flat x1.0 there).
**No login invite**: B037 adds `AiPlayerbot.InviteAltsOnLogin` to the bot
module (default 1, stock; documented in its playerbots.conf.dist) and skips
the login invite for a player's own bot when it is 0 (random bots never
affected); C030 sets it to 0 on basic (appending the key to an install
made before B037). C029 (`AiPlayerbot.KeepAltsInGroup = 1`) is kept: at
login the bot module still makes a bot leave any group its player isn't
in unless this is on; with it, far parties survive a relog instead of
being disbanded and rebuilt a pass later (not required, just less churn).
`scripts/test-source-patches <project> basic`: every patch applies and the
tree round-trips; `scripts/test-profile-config-gates`: 24 of 24.
Groups are changed on the world thread after all maps have updated (the
world-update hook), as the bot module changes its own.

Before: bots accepted group invitations through the bot module's
accept-invitation action; nothing re-formed a group by distance.

## Intended Behavior

Owner, 2026-09-27 (replacing "the owner and the four closest buddies"):
"they leave the group when they're far enough away, and rejoin it when
they are near and you don't have a full group."
- **By distance, not by rank**: checked every 5 seconds, a grouped buddy
  farther than the leave distance leaves the group; an ungrouped buddy
  nearer than the join distance joins, if the group has room. First
  **leave past 75 yards, join inside 54** (owner, 2026-09-27: a leave
  distance of 84 left "a thin region where the buddy-bot might still be in
  the player's party, but not be within XP radius. So we should sckooch it
  down to 75 and 54"): leaving just past the 74-yard experience radius, so
  a grouped buddy is almost never out of it, and joining well inside it,
  the 21-yard gap keeping a buddy at the edge from flickering in and out.
  Tuned in `docs/balance-updates.md`.
- **Join at 60, not 54** (owner, 2026-09-27: "Actually, I think 60 yards
  is the farthest a buff spell can go, so can we make that the range
  instead of 54?"). In the client's spell data no buff reaches 60: single
  buffs cast from 30 yards, group buffs (Prayer of Fortitude, Gift of the
  Wild, the greater blessings) from 40 and spread 100 yards round the
  caster, shouts 30. Built at 60 as asked; the 15-yard gap to the leave
  distance still stops flickering. Whether to match a real range instead is
  an open question.
- **The far buddies' own group** (owner, 2026-09-27: "if some buddy bots
  are far from the player but in the same area, they should join a group
  with each other so they share exp. And leave it if they become close to
  the player - within 74 yards. They only join the player's at 54 yards,
  though."): a buddy not in the owner's group and farther than 74 yards
  from the owner joins a group of such buddies; inside 74 it leaves that
  group, and inside 60 it joins the owner's if there is room. Between 60
  and 74 (or nearer with the owner's group full) it is in no group. A
  party holds five, so more than five far buddies make a second party. (A
  raid would also do: outside raid dungeons the server gives a raid group
  kill experience like a party, `KillRewarder` with
  `Acore::XP::xp_in_group_rate`; parties are kept because they need no
  conversion step and match the owner's own group.)
- Everyone ungrouped in towns and cities; a gathering buddy leaves when
  being grouped brings nothing (617c).
- Where the buddies go is 617e's roaming, not this issue: they don't try
  to stay near.

### Decisions, 2026-09-27 (Ritz): the group bonus, login grouping, far parties

- **No group bonus from buddies**: "oh, that's for getting human players
  to group up. We shouldn't apply it to buddy-bots." The server raises a
  group's kill experience by its size (×1.166 at three in range, ×1.3 at
  four, ×1.4 from five). Read: the bonus counts only the human players in
  range; buddies share the pool but add nothing to its size. Built through
  the server's kill-reward hook, which lets a module set each member's
  rate (`OnPlayerRewardKillRewarder`): the rate is scaled by the bonus for
  the human count over the bonus for the full count.
- **No grouping by playerbots at login**: "we can probably remove the
  playerbots buddy-group-up-at-login functions. We're using a different
  system for grouping up." Playerbots always invites a master's bot into
  the master's group at login (`GroupInviteOperation` from
  `PlayerbotMgr::OnBotLogin`), with no setting for it; a small playerbots
  patch adds one (`AiPlayerbot.InviteAltsOnLogin`, default on, stock
  behaviour) and basic's config turns it off, so only the proximity pass
  groups buddies.
- **Far parties merge only near each other**: "within 70 yards, leaving
  at 74. It's okay if they flicker a bit more." Two far parties merge
  when a member of one is within 70 yards of a member of the other (and
  the result fits in five); a far-party buddy more than 74 yards from
  every other member of its party leaves it (and may then join another
  far party within 70). Also (owner, same day): a far-party buddy leaves
  its far party "when it could join the player's party": within the
  60-yard join distance with room in the owner's party, it leaves the far
  party and joins the owner's in the same pass.

## Suggested Implementation Steps

1. A world-update pass per online owner: distances, current group, the swap
   with the margin; the far buddies' parties formed, filled and emptied by
   the same pass.
2. Town and city detection (617e's rule).
3. In game with a level-40 owner (five buddies).

## Open Questions

- (Answered 2026-09-27) The join distance: 60 ("let's do 60").
- **Raid experience** (owner, 2026-09-27: "can we update it to give the
  amount of experience that a 5 person group would give, but distributed
  to the raid group members who were within 74 yards of the player who
  earned the experience?"). Read in the source (`KillRewarder`): outside
  raid dungeons this is already so. A group's kill pays the killer's
  experience × a group bonus that grows with the members in range and
  stops at 1.4 from five members up, and that pool is split among the
  members in range by level; so a raid of ten in range shares what a
  party of five would, each getting a tenth. Two differences remain: "in
  range" is 74 yards from the slain creature, not from the killer (a
  hunter's kill 40 yards off counts members near the creature); and in a
  raid dungeon the bonus is a flat 1.0 whatever the number (marked FIXME
  upstream). Change either (a small server patch), or leave as is?
  (Answered 2026-09-27: "slain creature is better", so range stays measured
  from the creature. The raid-dungeon pool was explained back: inside a raid
  dungeon the group bonus stays ×1.0 however many members, where a party
  of five outdoors gets ×1.4.)
- (Answered 2026-09-27) Far parties merge: two far parties of the same
  owner merge while there is room ("Sure they can merge").
- **The far party's leader**: the lowest-numbered far buddy (a stable
  choice), or whoever has been far longest?

## Related Issues

- **617c** parent; **617c1**; **617e** the outer ring
