# 808 - Karazhan, an Endgame Raid in Azeroth

## Status
- Created: 2026-10-04
- Phase: 8
- Profile: basic
- Priority: Medium
- Related: 155 (basic profile), 155f (Outland dungeons raised for level 60),
  155k (the gear ladder, and the "Level-60 Gear Ladder" page), 155j (the
  Fel Reavers drop Karazhan epics), 155l (Outland without quests), 617c3
  (buddies drawn into instances; raids: all of a player's buddies)

## Origin

Verbatim, 2026-10-04:

> Can we add issue files to add Karazhan as an endgame raid? Because it's
> in Azeroth...

## Current Behavior

Not built. Karazhan (map 532, entrance in Deadwind Pass) is stock: a
ten-player level-70 raid with Burning Crusade loot (item level 115). On
basic it is reachable on foot (it is in Azeroth, not Outland), but its
monsters are far above a level-60 group, its entry needs the Master's Key
chain (Outland quests, disabled on basic by 155l), and its loot sits above
the ladder's top (Naxxramas-40, about epic item level 83-92).

## Intended Behavior

Karazhan is basic's endgame raid on the Azeroth side: entered at level 60,
its monsters raised the way the Outland dungeons are (155f) to a level a
geared level-60 raid can fight, its loot placed on the gear ladder (155k),
its door opened without the Outland key chain. A player's buddies fill
the raid (617c3: "For raids, all of your characters join you").

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 808a | karazhan-level | None | Its monsters set for level 60 by 155f's method (a level step per boss and wing) |
| 808b | karazhan-loot-on-the-ladder | 808a | Its loot rescaled onto the gear ladder (155k's method), at the place the owner picks |
| 808c | karazhan-door | None | Entry without the Master's Key chain: the key given another way, or the door's requirement lifted |
| 808d | karazhan-with-buddies | 617c3 | A raid of a player and their buddies: all of them join; the bot module's Karazhan tactics (it ships a "karazhan" strategy) checked at 60 |

Execution order: 808a and 808c first; 808b after 808a; 808d when the raid
draw exists.

## Suggested Implementation Steps

1. Read 155f's level-step generator and point it at map 532.
2. The ladder place (open question 1), then 155k's rescale for its loot.
3. The door (open question 2).
4. A test raid with buddies.

### Answers, 2026-10-04 (Ritz)

Verbatim:

> can we have kharazhan's item level rewards span from the level 60
> dungeon blues to the beginning 20% of Molten Core's item level
> distribution? Also, can we range the required level from 58 to 60 at the
> end for the final bosses, because they're that hard? It's an azeroth
> dungeon. It should be treated as such, but, it's a raid. Beginner raid.

> between BRD and MC's first 20% of item levels okay maybe not BRD it's
> item levels 58 and 47 for blues and epics respectively. Up until...
> let's say... 63? With a gap from 60. if there's any karazhan blues or
> w/e they can be 47 to 63 for epics, and 58 to... some other number for
> blues.

> can we add a flight path from a high vantage point that can see down
> onto it? The flight path creature can glide down, then walk back up with
> an escort waiting down below.

> I forgot the default size, is it 10? How parallelizable is this dungeon?

- **A beginner raid** on the Azeroth side, its loot from the level-60
  dungeon blues up to the bottom fifth of Molten Core's: Molten Core's
  drops (other than its Tier 1 set, item level 66) run from item level 58
  to 71, the bottom 20% at 61 or below, the median 65. Read as: Karazhan's
  epics item level 47 to 63, its blues from 58 up (top open), with "a gap
  from 60" (open question 4).
- **Required level 58 rising to 60** for the last bosses' loot.
- **The door** (808c): a flight from a high point that looks down on
  Karazhan; the flying mount glides down to the door and walks back up,
  and an escort waits below.
- **Size**: stock Karazhan is ten players. "How parallelizable": after
  Attumen and Moroes the tower opens into several bosses that can be done
  in any order (the Maiden, the Opera, the Curator's way, the Servants'
  Quarters), with a few bosses gated behind others (Shade of Aran and
  Netherspite behind the Curator; Chess, Prince and Nightbane later), so
  two groups could split for part of it. From memory of the stock raid;
  to be checked against its door and gate scripts.

## Open Questions

1. (Answered 2026-10-04) Between the level-60 dungeon blues and the bottom
   fifth of Molten Core (above).
2. (Answered 2026-10-04) A flight down from a vantage point (808c).
3. (Answered 2026-10-04) Ten, as stock: "if 10 is the default then 10".
4. "With a gap from 60": does it mean no item between some level and 60
   (which?), and where do Karazhan's blues stop?
