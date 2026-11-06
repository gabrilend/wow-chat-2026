# buddy_route_core.h

A buddy's way to its owner across maps as one route search over every way
(issue 617e8): walking, boats, zeppelins, portals and a mage's own
teleports, the quickest route taken. Plain arithmetic, no server; checked
by `scripts/test-buddy-route`. Not yet wired into the server: the crossing
(`buddies_crossing.cpp`) is to give it the ways it knows and carry out the
first leg of its answer.

## Numbers

| Name | Value | Meaning |
|---|---|---|
| `RUN` | 7.0 | run speed, yards a second |
| `DETOUR` | 1.3 | a real walk over the straight line |
| `PREFER` | 0.9 | the owner's own way counts this share of its time when choosing |

## Pieces

| Name | What it is |
|---|---|
| `Place` | `map` (uint32), `x`, `y` (double) |
| `Kind` (uint8 enum) | `Walk`, `Sail`, `Portal`, `Teleport` |
| `Link` | `kind`, `from`, `to` (Place), `wait`, `seconds` (double: until it leaves, then the ride or cast), `anywhere` (bool: a teleport, cast where the buddy stands), `owners` (bool: the way the owner took), `id` (uint32, the caller's own) |
| `Walk(a, b)` | -> double: seconds at `RUN` times `DETOUR`; infinity across maps |
| `LinkSeconds(link)` | -> double: wait + seconds, times `PREFER` for the owner's way (for choosing only) |
| `Leg` | `kind`, `link` (int: -1 walked, else the link's index), `from`, `to`, `seconds` |
| `Route` | `found` (bool), `seconds` (double: the legs' full times), `legs` |
| `Find(start, goal, links)` | -> Route: Dijkstra over the start, the goal and each link's ends, walking between any two on one map, a teleport from any place reached |
| `Stop` | `at` (Place), `arrives` (double: seconds until the ship docks there) |
| `BestStop(ahead, goal, links, seconds)` | -> int: of the stops ahead, the one whose docking plus route to the owner ends soonest (-1: none reaches it); the total through `seconds` |
