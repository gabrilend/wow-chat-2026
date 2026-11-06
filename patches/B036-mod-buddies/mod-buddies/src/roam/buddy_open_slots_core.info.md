# buddy_open_slots_core.h

The other follow mode, "nearest open slot" (issue 617s8): the close
follow's ring round the owner, but no buddy owns a compass place. Each
slot is claimed by at most one buddy; a buddy that reaches its waypoint
lets its claim go and claims the free slot nearest to where it stands.
Plain arithmetic, no server; checked by `scripts/test-buddy-open-slots`.
Not yet wired into the server: the switch at Chromie (168) and the ring
follow choosing by it are the server's part, still to build. In compass
mode nothing changes (`BuddyFollow::AssignRing`).

## Pieces

| Name | What it is |
|---|---|
| `Follower` | `id` (uint32), `at` (Point), `tank` (bool): given each update; `slot` (int, -1 none), `waypoint` (Point): kept by the server per buddy |
| `Answer` | `walk` (bool), `to` (Point), `facing` (float, radians: toward the owner when standing) |
| `Straight(a, b)` | -> float: the default distance, a straight line on the ground |
| `ShareSearch(...)` | the pickers share the free slots by least distance in all (every arrangement, cut off when longer than the best) |
| `Step(fs, slots, owner, s[, dist])` | -> one Answer per follower; claims kept, let go and taken in place |

## The rules, as `Step` applies them

| Who | What |
|---|---|
| a claim on a slot the ring no longer has | let go |
| the tank (the first follower marked so) | holds slot 0, the front (617s3); whoever held it is displaced, even mid-walk |
| a buddy walking to its waypoint (farther than `ringSlack`) | keeps its claim and its waypoint |
| a buddy at its waypoint, or holding nothing | lets go, then claims the nearest free slot by `dist`; several at once share by least walking in all |
| the owner standing still | a buddy at its slot finds its own the nearest: it stays (decided 2026-11-06) |

`dist` is the caller's: the navigation mesh's path length in the server,
`Straight` by default.
