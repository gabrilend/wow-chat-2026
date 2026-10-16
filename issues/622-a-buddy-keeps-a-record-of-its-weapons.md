# 622 - A Buddy Keeps a Record of Its Weapons

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 617j (buddies and loot: how an upgrade is judged today), 621
  (an enchant changes what a weapon does), 309 (monsters that test their
  foes: the same idea from the other side)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-15:

> And the bots should have the capability to view the DPS of the weapon
> and kills-per-minute of it over time. So they can properly learn to
> evaluate new things they were not trained for. Creativity, of their
> form.

Asked how a buddy weighs the two: "it taught itself. tool use."

## Current Behavior

A buddy judges a weapon only by its listed numbers: the bot module's stat
weights for its talent shape (`playerbots_weightscale_data`), applied to
the item's stats and listed damage per second (617j's scoring in
`buddies_loot.cpp`). What a weapon actually did in its hands, how fast
things died while it held it, is not recorded anywhere.

## Intended Behavior

1. **The record.** For every weapon a buddy has held, it keeps: the
   listed damage per second, the time it was held in fights, the kills
   made while holding it, and so the kills per minute of fighting, along
   with the levels of what it killed (a kill of a much lower monster
   counts for less). Kept in the characters database, so it lasts across
   logins.
2. **Its own judgment.** When it weighs a new weapon, it compares the
   listed numbers with what it has learned: how kills per minute have
   followed listed damage per second across the weapons it has held (its
   own line through its own points). A weapon kind it has never held
   (its first staff) is judged by the listed numbers alone until it has
   held one; after that, by what the line says. Nobody hands it the
   weights: it measures them. Tool use.
3. **Visible.** A console command (and a whisper) shows a buddy's record:
   each weapon, listed damage per second, kills per minute, minutes held.

## Suggested Implementation Steps

1. Answer the open questions.
2. A table `buddy_weapon_record` (buddy guid, item entry, minutes in
   combat, kills, summed level difference of kills), written by the
   buddy module at the end of each fight and on logout.
3. The counting: a kill hook for the buddy's kills (and its pet's?), and
   combat time from entering to leaving combat, both credited to the main
   hand held at the time.
4. The judgment: a small fit (kills per minute against listed damage per
   second, per weapon kind) read when the loot rules weigh a weapon
   (617j), with the record's count of minutes deciding how far it is
   trusted.
5. The command, and an offline test of the fit with made-up records.

## Open Questions

1. A kill by the group (the owner or another buddy struck the last blow):
   counted for every buddy who was hitting, or only the killer?
2. How far should its own measure override the listed numbers: until it
   has held a weapon for some minutes the listed numbers rule, and after
   that its own line rules entirely, or a blend?
3. Should a buddy say something when its record changes its mind ("this
   axe kills faster than its numbers say")?
