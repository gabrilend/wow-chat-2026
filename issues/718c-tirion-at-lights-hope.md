# 718c - Tirion Holds the Ashbringer at Light's Hope

## Status
- Created: 2026-10-13
- Phase: 9
- Parent: 718 (death knight sacrifice and open Acherus)
- Related: 155 (basic: Northrend not opened)
- Priority: Low
- State: planned; open questions first

## Origin

Verbatim, 2026-10-13:

> Also, we should have Tirion Fordring with the Ashbringer at Light's Hope
> Chapel because we haven't opened Northrend yet. But, we should send him
> there if we ever enable the quests out there, which we haven't.

## Current Behavior

At the end of the death knights' story ("The Light of Dawn"), Highlord
Tirion Fordring appears at Light's Hope Chapel with the Ashbringer only
for the battle (creature 29175, never spawned for good). Afterward, stock
3.3.5 has him in Northrend (Highlord Tirion Fordring, several creatures
on map 571). On basic, Northrend isn't open, so a player never sees him
after the battle.

## Intended Behavior

Highlord Tirion Fordring stands at Light's Hope Chapel, holding the
Ashbringer, for as long as Northrend's quests are not enabled. The day
they are enabled he leaves for Northrend, as in the stock game: the
spawn is gated on the same switch that opens Northrend's quests.

## Suggested Implementation Steps

1. Answer the open questions.
2. A spawn at Light's Hope (map 0, the Eastern Plaguelands) of a Tirion
   with the Ashbringer in hand (the Light of Dawn creature's look and
   weapon), in a basic install step, with its revert.
3. Gate it on Northrend: the install step for the profiles where
   Northrend's quests are off; a note where Northrend gets switched on.
4. In game: fly to Light's Hope, look.

## Open Questions

1. Does he do anything (a few lines when spoken to, a quest, a vendor),
   or simply stand there?
2. Where exactly: inside the chapel, or outside where the battle ended?
3. Every profile where Northrend is closed (basic, vanilla), or basic
   only?
