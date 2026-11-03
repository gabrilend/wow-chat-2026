# 617e17 - An Army of Sixty-Four

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e (buddies in the world)
- Related: 617o7 (the five ways they test), 136d (the test realm they
  live on), the stand-ins (`buddies_stand_ins.cpp`), 617e16 (the
  sandboxes, where the white dot is the player), 1100e (the realm locked
  to game masters)
- Priority: High
- State: in progress (planning)

## Origin

The owner, 2026-10-28:

> We should have stand-in buddy-bots, say an army of 64, just for me, and
> my buddy-bots should displace some of them, so it's always a total of 64
> (for the scenario setup scene jumps we're planning for later) - anyway
> they will quest in the area that my character is in, as if they were the
> white dot. remember, random buddy-bot stand-ins. They should behave as if
> we were all in one clan, and in-fact, for these purposes, you can make it
> so. But this is for the test server probably...

## Current Behavior

**Written 2026-10-28, not yet compiled** (`buddies_army.h`,
`buddies_army.cpp` in the buddy module; additions to the stand-in maker,
`buddies_stand_ins.cpp`: whether a stand-in is still on its way, sending
one out, and a character's talent plan read from whichever table holds
it; the roster's list, `buddies_roam_ground.cpp`, adds the army's
stand-ins after its own).

- `.buddy army` (game masters) raises an army of 64 round the speaker;
  `.buddy army <count>` (1 to 200) raises or resizes it; asked again with
  no number it says how it stands (own buddies, stand-ins in the world and
  how many follow the game master, on their way, brought, displaced);
  `.buddy army dismiss` sends every stand-in out, kept for the next asker.
- Every two seconds the army is kept up: the game master's own buddies in
  the world count first; stand-ins make up the rest, up to four asked for
  each pass (64 come in about half a minute), each of the game master's
  side and level, random race and class, then one of the ten talent
  shapes a buddy can have, drawn at random with every shape equally
  likely, its role whatever that shape's is (the owner, 2026-10-29:
  "fully random talent spec profile distribution"; until then every
  fifth was a tank and the next a healer, a party's shape), placed
  within 8 yards of them. Too many for the room their own buddies
  leave: the newest stand-ins go out (displaced). A stand-in that left
  some other way is let go. The game master logging out ends the army.
- **One clan, as 64 buddies** (the owner, 2026-10-29: "we should treat
  them like as if we had 64 buddy-bots"): the clan is the set of an
  owner's buddies, so a stand-in, once its first moments are done (its
  behaviours reset and moved to its place), takes the game master as its
  master, and the roster's list holds it as their buddy. Every pass that
  reads the roster then takes it as one: roaming (a buddy's open-country
  behaviours: it roams the area the game master is in and fights what it
  meets, by the way `.buddy path` picked for the game master's buddies),
  the parties, the orders, the following, the map page, the dungeon draw.
  The army's own count of "your buddies" leaves its stand-ins out. One on
  another map than the game master is brought to them. The bot module
  keeps the master: it lets go of a bot's master only for its own random
  bots, and the stand-ins' accounts are not on its random list.
- **Grouped as buddies are** ("Buddy-bot stand-ins should be sorted into
  groups correctly"): four join the game master's party by the usual
  distance rule; the rest form five-person parties of their own with the
  buddies near them, near the game master as well as far (617c2's
  decision of 2026-10-29: while the owner's party has no seat free, the
  buddies near it keep to their own parties).
- **Gems by their plan**: a stand-in's talent shape and role are in its
  own table, not the roster's, so the readers that asked the roster's
  table alone (the gem chooser handing found gems round the clan, its
  auction-house buying, the dungeon draw's roles) now ask for the plan
  from whichever table holds it. Its sockets are filled free at its
  making and when it is raised to a new level, as a buddy's; a raised
  stand-in's PvP necklace, rings and trinkets, given after that, are now
  gemmed too.
- **Test realm only**: the command refuses unless the module's setting
  `Buddies.TestRealm` is on, which the launcher sets for a realm branch
  (136d; `pathtest`, realm 7, is made).

A syntax-only check of the four changed files against the server's
headers passes; the owner's compile is the real test, then trying it in
game.

## Intended Behavior

- **Sixty-four, always.** On the test realm, a game master can raise an
  army of 64 round their character: their own buddies first, then random
  stand-ins (made as stand-ins are, random races, classes and looks) to
  make up 64. A buddy of theirs logging in displaces a stand-in; logging
  out, a stand-in takes its place.
- **One clan.** The army and the player are one clan (the clan the
  buddies already share; the stand-ins joined to it for the test), so
  they treat each other as clan-mates.
- **Questing round the player**, as the sandbox's bots do round the white
  dot: wandering the area the player is in, fighting what they meet, by
  whichever of the five ways (617o7) is switched on.
- **Test realm only**: the commands refuse on a realm that isn't a test
  branch (136d).

## Suggested Implementation Steps

1. `.buddies army [count]`: raise or top up to the count; `.buddies army
   dismiss`.
2. Displacement when the player's own buddies come and go.
3. The clan join for the test; refused off the test realm.
4. Tried with the owner after the compile.

## Open Questions

1. **"scenario setup scene jumps we're planning for later"**: the 64 is
   kept constant for those; should the army's makeup (which stand-ins,
   their classes) be fixed from one jump to the next, or drawn again?
   **Read from question 2's answer, 2026-10-29** ("fully random"): drawn
   again at each jump. That is the agent's reading, for the owner to
   correct. **The owner, 2026-10-30, word for word:** "they are rebuilt
   dynamically. But, we will often be using the same ones. They come
   from the same pool as the stand-ins." Rebuilt at each jump, drawn
   from the stand-ins' pool, so the same characters often come back.
2. **The army's shape** (answered 2026-10-29): asked whether it should be
   party-shaped (a tank and a healer in every five) at the game master's
   level and side, the owner: "fully random talent spec profile
   distribution." Each stand-in's race and class are drawn from its
   side's pairs, then its talent shape from all ten, each equally likely;
   its role is the shape's. The game master's level and side stay.
3. **Grouping** (answered 2026-10-29): asked whether the stand-ins, in no
   group with the game master (64 is more than a raid of 40), should be
   put in five-person parties among themselves, the owner: "Yeah we should
   treat them like as if we had 64 buddy-bots. For the test scene, that's
   exactly what we'll do." So the army is treated everywhere as the game
   master's buddies, grouped as buddies are.
