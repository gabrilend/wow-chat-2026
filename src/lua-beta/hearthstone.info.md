# hearthstone.lua

A group hearthstone by invitation (issue 211). When a grouped player
begins a Hearthstone or Astral Recall, the other players are asked in a
window whether to come along; bots always come. Those counted in travel
when the cast completes, to a circle round the hearther's bind point, each
at the place of their number in the group. A cancelled or interrupted
cast, or the hearther logging out, calls it off. Other scripts open the
same invitation for their own spells and place the travellers themselves
(the druids' Moonglade trip, `druid-moonglade.lua`, issue 211a). Checked
offline by `scripts/test-hearthstone`.

## Functions

- `GroupHearth.onPrepare(event, caster, spell)`: a Hearthstone or Astral
  Recall cast begins (the engine's per-spell event); opens the hearth.
- `GroupHearth.onCancel(event, caster, spell, bySelf)`: the cast is
  cancelled or interrupted; withdraws the hearth.
- `GroupHearth.onLogout(event, player)`: a hearther logging out mid-cast;
  withdraws the hearth.
- `GroupHearth.open(player, kind) -> hearth or nil`: opens a hearth for
  any spell: asks each player, counts in bots. `kind` is `{ question,
  confirm }`, two strings each with one `%s` for the hearther's name. Nil
  when not grouped.
- `GroupHearth.take(guid) -> list of { guid, place }, group size`: for a
  script placing the travellers itself, at its spell's completion: those
  who said yes, still online and alive, with their number in the group;
  closes the hearth.
- `GroupHearth.onAnswer(event, player, object, sender, intid, code, menu)`:
  an answer in the window (1 come along, 2 stay); `sender` is the
  hearth's number.
- `GroupHearth.onCast(event, player, spell)`: a cast completes; for
  Hearthstone (8690) or Astral Recall (556) of an open hearth, moves the
  counted-in members 1.5 seconds later.
- `GroupHearth.withdraw(hearth)`: closes open windows and forgets it.
- `GroupHearth.circle(cx, cy, n) -> list of { x, y }`: n places round a
  point, at least 2.5 yards apart, never nearer than 3 yards.

## Data

`GroupHearth.pending`, by the hearther's guid: `{ id = number,
hearther = guid, name = string, kind = { question, confirm },
members = list of guids in group order, accepted = { [guid] = true },
asked = { [guid] = true }, done = boolean }`. Players are kept by guid and
looked up again when needed. `GroupHearth` is made here only;
`druid-moonglade.lua` uses it when a spell is cast.
