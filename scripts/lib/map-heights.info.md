# map-heights.lua

The outdoor terrain's height anywhere on a map, from the server's map files
(`data-files/maps/MMMXXYY.map`, version 9), read lazily, one grid at a time
(issue 617e12). Caves and buildings are not in it, which is what makes it
useful beside the walking mesh: a floor well below it is under a hill.

| Function | Takes | Gives |
|---|---|---|
| `map(dir, map)` | project folder, map id | `terrain`, whose grids are read on first use |
| `terrain:height(x, y)` | game coordinates | the height (float) at the nearest of the grid's points (4.17 yards apart), or `nil` where the map has no file for that grid |

The file format and the index arithmetic are in the file's header comment.
