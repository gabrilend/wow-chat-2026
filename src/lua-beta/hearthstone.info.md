# hearthstone.lua

A group hearthstone by invitation (issue 211). When a grouped player
starts a hearthstone, the other players are asked in a window whether to
come along; bots always come. Those counted in travel when the cast
completes, to a circle round the hearther's bind point, each at the place
of their number in the group. A hearth not completed within 12.5 seconds
is called off. Checked offline by `scripts/test-hearthstone`.

## Functions

- `GroupHearth.onUse(event, player, item, target)`: the Hearthstone item
  is used; opens the hearth, asks each player, counts in bots, sets the
  call-off timer.
- `GroupHearth.onAnswer(event, player, object, sender, intid, code, menu)`:
  an answer in the window (1 come along, 2 stay); `sender` is the
  hearth's number.
- `GroupHearth.onCast(event, player, spell)`: a cast completes; for
  Hearthstone (8690) or Astral Recall (556) of an open hearth, moves the
  counted-in members 1.5 seconds later.
- `GroupHearth.withdraw(hearth, why)`: closes open windows and forgets it.
- `GroupHearth.circle(cx, cy, n) -> list of { x, y }`: n places round a
  point, at least 2.5 yards apart, never nearer than 3 yards.

## Data

`GroupHearth.pending`, by the hearther's guid: `{ id = number,
hearther = guid, name = string, members = list of guids in group order,
accepted = { [guid] = true }, asked = { [guid] = true }, done = boolean }`.
Players are kept by guid and looked up again when needed.
