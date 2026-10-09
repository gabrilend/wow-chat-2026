# 176a2d - Arathi Basin: Squad Formations

## Status
- Created: 2026-10-08
- Phase: 1
- Parent: 176a2 (an Arathi Basin match)
- Blocked by: 176a2b (squads)
- Related: 619 (combat footwork: what they do once a fight starts), 176a
  (the movement coroutines: "orbit your foe", "turn while walking"),
  617e5 (buddies fighting together)
- Priority: Medium

## Origin

The owner, 2026-10-08 (whole request in 176a2): "Stand-ins should be able
to "group up" when there's nobody around and travel in a formation -
either two in front with the healer behind, or two to the sides and the
tank in front with the healer behind. So, triangle or diamond shape."

## Current Behavior

**2026-10-08: the shapes are built on paper; no squad walks them yet.**
`src/lua-cc-test/lib/arathi-basin-formations.lua`: triangle, diamond and
line, each member's spot from the squad's middle and its road's heading,
and the calm check. Open questions built both ways: question 1 (`spacing`
3 or 5 yards, `calm_range` 20 or 40), question 2 (`narrow` = "line" or
"keep"), question 3 (`small` = "line" or "follow"). At spacing 5 a
diamond is 10 yards across and its healer 10 yards from the tank; at
spacing 3, 6 yards. Checked by `scripts/test-arathi-basin-rules`.

Before this, not built. The bot module's bots in a group follow their leader in a
loose cluster, or walk alone in battlegrounds.

## Intended Behavior

- **When.** No enemy within sight (a distance to be set), the squad
  closes up into its shape and walks its route that way. An enemy comes
  into sight: the shape breaks and each fights (619's footwork). The
  fight over and nobody near: the squad closes up again where it stands.
- **Triangle (a trio).** The two damage stand-ins in front, side by side;
  the healer behind them, in the middle.
- **Diamond (with a tank).** The tank in front; the two damage
  stand-ins to the left and right; the healer behind.
- **Facing the road.** The shape points the way the route goes next and
  turns with it at bends, so the one in front is always in front.
- **Spacing.** A few yards between them, so none stands inside another,
  and close enough that the healer reaches everyone.
- **Keeping pace.** The shape walks at its slowest member's speed (the
  Stables bonus, 176a2e, can make them differ).

## Suggested Implementation Steps

1. The shapes as offsets from a centre that moves along the route,
   rotated by the road's direction: plain math, tested without a server.
2. Each member steering to its slot (176a's movement coroutines).
3. The switch: enemy in sight breaks the shape, none in sight for a
   moment closes it.
4. Logs: each member's distance from its slot over time, for 176a2f.

## Open Questions

1. **Distances:** how far is "nobody around" (the stock aggro range is
   about 20 yards; sight is far more), and how many yards between members?
2. **Narrow ground:** on a narrow path (the Lumber Mill ramp), does the
   shape squeeze into a line, or keep its shape and let members walk off
   the road?
3. **A squad of two or one** (after deaths): any shape, or just follow?
4. **Players:** if a player walks with a squad, do they get a slot, or
   does the squad shape itself round them?
