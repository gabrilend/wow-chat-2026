# 169 - Nearby Duels Are One Fight; Duels End at 20%

## Status
- Created: 2026-10-04
- Phase: 1
- Profile: basic
- Priority: Medium
- Related: 170 (the sparring grounds use both rules)

## Origin

Verbatim, 2026-10-04:

> Also, we should make it so that anyone who is in a duel can fight and
> deal damage to anyone else who is in a duel near them.

> Also, duels end at 20% health on this server.

## Current Behavior

Not built. Stock: a duel is between two players only; a dueller can't
harm anyone else, and the duel ends when one would drop to 0 health (they
are left at 1).

## Intended Behavior

Owner, 2026-10-04: "dueling should just be consenting to
free-for-all-ing. If you drop to 20% health you can't be targeted or ask
for duels or be asked until you hit 100% health again."

- **A duel is consent to a free-for-all**: anyone in a duel may attack,
  harm and heal anyone else in a duel (no distance limit beyond being
  able to reach them), as well as their own opponent.
- **Out at 20%**: a duellist who would drop below 20% of their health
  stops there and is out: nobody can target them, and they can neither
  ask for a duel nor be asked, until their health is full again.
- **Healers from outside** (owner, 2026-10-04: "healers should be able to
  heal anyone in a duel without being engaged in a duel. They will run
  out of mana eventually."): anyone may heal a duellist without joining
  the fight.
- **No eating where you fight** ("can we remove the health restorative
  effects of food and water when near a duel? It's not good to fight where
  you eat. So characters have to either walk far away (back into the
  city, to a cafe or something for food) or they can just sit by the fire
  with their allies at the duel place."): food and drink restore nothing
  near a duel (a radius round each duellist, open question 4); campfires
  (170) still help.
- **Monsters hit duellists twice as hard** (owner, 2026-10-04: "also
  monsters deal 2x damage to dueling characters").
- **Posts stay manned** ("there must be the correct number of combatants
  at all time, so if they want to leave another ally will walk to the
  duel area, until that time they wait, when the ally arrives they can
  swap places and go wander about."): at a duel post (170), a fighter who
  wants to leave waits until a replacement has walked up, then swaps out.

## What the server and client do today (read 2026-10-05)

From the upstream source (`Unit.cpp`, `Player*.cpp`):

- **Who may attack whom**: the attack-validity check allows a player
  to attack another player only as its own duel opponent (one pointer
  comparison, before the sanctuary checks), and the reaction check makes
  only the opponent hostile. Everyone else in a duel is "friendly".
- **The client decides too.** The game client works out hostility itself
  from what the server tells it about each unit. Two players in two
  different duels look friendly to each other's clients, which will not
  let them start an attack, whatever the server allows. The one flag the
  3.3.5 client already understands for "anyone flagged may hit anyone
  else flagged" is the free-for-all PvP flag (the one Gurubashi Arena
  sets). So the free-for-all rule is the FFA flag, set on every duellist
  when the duel starts and cleared when it ends. The server rewrites that
  flag on zone changes and PvP timers (`UpdateFFAPvPState`, called from
  the player's update), so the patch must also treat "in a duel" as being
  in an FFA area there, or the flag gets wiped seconds later.
- **The 0-health stop**: the damage path stops a hit at 1 health only
  when it comes from the duel opponent (or the opponent's pet); a hit from
  anyone else kills. A duel is always a pair. When one of the pair is
  beaten, the other wins, and both leave the duel.
- **Healing a duellist**: the assist check refuses any help to a player
  who is duelling someone, and any help from outside an FFA area to a
  player inside one. Outside healers (owner: "healers should be able to
  heal anyone in a duel") need both refusals lifted for duellists.
- **Food and drink** are ordinary auras that heal over time. Stopping
  them near a duel means a change in the periodic heal/energize handling
  (C++), or removing the aura from Lua as it lands. ALE has no event for
  "aura applied", so it would have to be C++ or a polling sweep.
- **Monsters twice as hard**: basic's damage-multiplier rules
  (`basic_rules.cpp`, 155i) already scale damage per creature. A
  "victim is duelling" factor can go in the same place.

## Suggested Implementation Steps

Split by mechanism, each one testable on its own:

1. **Free-for-all (C++ patch)**: the FFA flag on at duel start and off at
   the end, kept through `UpdateFFAPvPState` while duelling; attack
   validity and reaction treat two players with duels in progress as
   hostile.
2. **Out at 20% (C++ patch)**: any hit from a player-controlled unit
   that would take a duellist below 20% of maximum health stops at 20%
   and ends that duellist's duel as a loss. Then, from Lua (ALE's
   duel-end event): unselectable (`UNIT_FLAG_NOT_SELECTABLE`) and duel
   requests refused until health is full, checked on a timer.
3. **Outside healers (C++ patch)**: lift the two assist refusals when
   the target is a duellist.
4. **Monsters x2 against duellists**: one factor in `basic_rules.cpp`.
5. **No food or drink within 100 yards of a duellist**: C++ in the
   periodic aura handling.
6. **Posts stay manned**: belongs to the sparring grounds (170), which
   wait for stand-ins (617t).
7. In game: three duels side by side; strikes across them land; an
   outside priest heals; a loser stops at 20% and can't be targeted; a
   monster hits a duellist twice as hard; bread does nothing near them.

## Open Questions

1. (Answered 2026-10-04) No "near": a duel is consent to fight every
   other duellist.
2. (Answered 2026-10-04) Healing across duels: part of the free-for-all.
3. (Answered 2026-10-04) At 20%: out, untargetable, no duels either way
   until full health.
4. (Answered 2026-10-04) Food and drink stop working within 100 yards of
   a duellist.
5. The free-for-all needs the FFA PvP flag (see above). Duellists will
   show each other as hostile (red names) and may be hit by anyone else
   with that flag, which means other duellists and players inside an
   arena like Gurubashi. Is that acceptable?
6. Can a monster (not a duellist) still kill a duellist, or does every
   hit stop at 20% while they are in a duel?
7. Duels are pairs: when A is beaten, A's opponent B wins and leaves the
   free-for-all too, though nobody beat B. Should B stay in (still
   flagged, still fighting) until B asks for a new duel, or is
   "leaves with the win" right?
