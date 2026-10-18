# 211 - Group Hearthstone, by Invitation

## Status
- Created: 2026-10-17
- Phase: 2 (The Empty World: getting around it together)
- First profile: beta (`src/lua-beta/hearthstone.lua`, from wow-chat-1)
- Related: 617e (the buddies' hearthstone, same family: its 2026-10-17
  decision), 168 (Chromie: another talking helper with menus), 617b
  (Sargobras's menus and pop-ups, the technique reused here)
- Priority: Medium
- State: planned; open questions first

## Origin

wow-chat-1's group hearthstone (`hearthstone.lua`, written by hand by the
owner) pulls a group to the member who hearths. The 2026-10-17 audit found
it stops at the hearther in the member list (members after them never
come), points arrivals in a meaningless direction, and pulls everyone even
when the hearth was cancelled. Shown how the buddies' version works
(`src/lua-basic/buddy-hearth.lua`), the owner, verbatim:

> can we give a pop-up notification to the player, like the summon spell?
> That should complete when the player completes the hearthstone cast.

> sitting down to decline is a dumb idea because how do you know they're
> hearthing? Jeez since I saw that we can make custom pop-up notifications
> with okay/cancel boxes when we did it with Sargobras for the clan name
> system, I realized we had so much inherent power that I didn't realize
> when I was coding this by hand. Thank you!

> I realized that is silly. Can we just do it by group number? They should
> spawn in a circle around the first hearther's hearth position.

## Current Behavior

**Built on branch beta-homework (2026-10-17)** as described in Intended
Behavior, with the open questions answered by default for now (each
marked in the script's header): bots in the group always come; a second
hearther is asked like anyone else and, if they accept, travels with the
first; the window is the clan-name kind (accept now, move at completion).
`src/lua-beta/hearthstone.lua` (summary beside it); checked offline by
`scripts/test-hearthstone` (140 checks: the circle for groups of 2 to
40, a group of four answering yes and no, a cancelled hearth, a member
logging out in between, a lone player, another spell), which runs before
every build. Not yet seen in game.

What it replaced (wow-chat-1's, kept here as the record):


`src/lua-beta/hearthstone.lua`, on the Hearthstone item's use (item 6948,
the moment the cast begins):

- walks the hearther's group list and, for each member before the
  hearther, says "You are being teleported to X's hearthstone. You may sit
  down to cancel the teleport.", plays a level-up flash on them every 3
  seconds, and after 10 seconds, if they are standing, teleports them to a
  random spot 5–10 yards from wherever the hearther then stands;
- stops at the hearther: members listed after them are never pulled;
- faces arrivals by `tan(x / y)`, which points nowhere in particular;
- does not know whether the hearth finished: a cancelled hearth still
  pulls the group, to the spot the hearther stood when they cancelled.

## Intended Behavior

1. **The invitation.** When a group member starts a hearthstone (or a
   shaman's Astral Recall), every other member who is a player gets a
   pop-up: "<name> is hearthing to <place>. Come along?" with Okay and
   Cancel, the way Sargobras asks for a clan's name (a gossip menu with a
   confirm box, sent to the player without an NPC).
2. **It completes with the cast.** Members who pressed Okay are moved when
   the hearther's cast completes, not before. A cancelled or interrupted
   cast withdraws every open pop-up and moves no one.
3. **Where they land: by group number, round the first hearther's
   arrival.** The first member to hearth sets the spot: their hearthstone's
   destination (their bind point). Accepting members stand on a circle
   round it, each at the place of their number in the group (1 to 5 in a
   party, 1 to 40 in a raid), so a member's place does not depend on who
   else came. Facing: any direction.
4. **A second hearther** in the same group while the first is under way
   joins the same circle (open question 2).

## Suggested Implementation Steps

1. Detect the start, completion and cancellation of the cast: the start
   from the item use (as now) or the spell-cast event, the completion from
   the cast-complete event (the buddies' script uses
   `PLAYER_EVENT_ON_SPELL_CAST`, which fires as a cast completes), and the
   cancellation as "start seen, no completion within the cast time plus a
   margin, or a new cast began".
2. The pop-up: a player-sent gossip menu (`player:GossipMenuAddItem` with
   the confirm-box arguments, `player:GossipSendMenu` with the player as
   sender, `RegisterPlayerGossipEvent` for the answer), modelled on
   `src/lua-basic/sargobras.lua`'s clan-name pop-up. Withdraw with
   `player:GossipComplete()`.
3. The circle: run basic's `lib/buddy-arc.lua` in place (as
   `src/lua-cc-test/buddy-talents.lua` runs basic's file, so the two never
   drift), or a ring of its own if group numbers want a different spacing.
4. Keep the stale-object lesson of issue 210: never hold a player object
   across a delay; keep names or guids and look players up again.
5. Tests: offline, the circle (every group size, places distinct, nobody
   on the centre, a member's place fixed by number), and the sequence
   (accept then cancel moves no one; accept then complete moves only the
   accepted; a member who logged out in between is skipped without an
   error). In game, a party of two players.

## Open Questions

1. Random bots in a player's group can't press a button. Do they always
   come, never come, or come only when the hearther is their group's
   leader?
2. Two members hearthing at once: one circle round the first hearther's
   destination for everyone, or does the second hearther's own pop-up go
   out too?
3. "Like the summon spell": the game's own summon dialog ("X wants to
   summon you to Y") moves the player the moment it is accepted, to where
   the summoner stands, so it can't wait for the cast to finish. The plan
   uses Sargobras's kind of pop-up (accept now, move at completion). Or
   should the game's own summon dialog appear at the moment the hearth
   completes, from the arrival spot (accept moves you; the circle placing
   happens after)?
