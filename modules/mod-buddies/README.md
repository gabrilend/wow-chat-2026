# mod-buddies

The project's own AzerothCore module for buddies: each player character's
bot companions on the basic profile (issue 617, starting with 617a).

It lives in the project, not in the cloned server tree. Source patch B036
copies it into `source-beta/modules/` before a build and removes the copy
afterwards, so the server tree still round-trips to upstream.

Files:
- `src/buddies_loader.cpp` — the module's entry point; lists its scripts.
- `src/buddies.h` — what the files share: whether buddies are on, and how
  a companion account is named, found and recognised.
- `src/buddies_roster.cpp` — checks at startup that the two roster tables
  exist (install step E042); buddies stay off without them.
- `src/buddies_clan.cpp` — each owner's hidden companion account and owed
  slots: made with the character, caught up at login and level-up,
  deleted with the character or its account (617a2).
- `src/buddies_create.cpp` — every few seconds, a chosen roster row
  becomes a character of that race and class at the owner's level, on the
  owner's companion account (617a3). (It joins the owner's clan guild 5
  seconds after it first appears, from the Lua side, 617l.)
- `src/buddies_login.cpp` — buddies log in with their owner as the
  owner's bots (the companion account linked to the owner's in the bot
  module's account-link table) and appear 20-30 yards away; the bot module
  logs them out with the owner (617c1).
- `src/buddies_clan_lock.cpp` — a clan guild can't be disbanded, left,
  handed over or opened to others: those five guild requests are turned
  back at the server's incoming-request hook (617l).
- `src/buddies_roam.h` — what the roaming and grouping files share.
- `src/roam/buddy_roam_core.h` (+ `.cpp`) — the roaming core: where a
  buddy goes next and the path there, with no server calls (617e2).
- `src/roam/buddy_explore_core.h` (+ `.cpp`, `.info.md`) — exploring as
  painting: the ground grid, paint, rooms and tunnels, the squished circle,
  and the least-paint, room-orbit and squished-circle choosers, with no
  server calls (617e6).
- `src/buddies_explore.cpp` (+ `buddies_explore.h`) — those in game: each
  area's grid measured from the map (a few hundred cells a world tick, then
  finished on a worker thread), each clan's paint, and ".buddy explore
  <pinwheel|paint|rooms|disc|mixed>" (617e6).
- `src/buddies_roam_ground.cpp` — the core's questions answered over the
  real map (heights, the named area's edge, sharp steps), each area's
  centre found once, and the buddy list the passes read (617e2).
- `src/buddies_roam_strategy.cpp` — the bot-module behaviour "buddy
  roam", taught to all ten classes at startup, walking the core's paths;
  and a pass keeping each buddy's peace-time behaviours right (617e1).
- `src/buddies_town.cpp` (+ `buddies_town.h`) — the bot-module behaviours
  "buddy travel" (walk to the owner's named area) and "buddy town" (in a
  town: errands at the class trainer, a vendor and a repairer, then
  leisure: townspeople, chairs with shared timers, sleep by the inn),
  taught to the bot module by the strategy file (617e4).
- `src/buddies_party.cpp` — groups by distance from the owner: the
  owner's party within 60 yards (leave past 75), far buddies' own parties
  past 74 (617c2); needs config patch C029 (KeepAltsInGroup).
- Coming: 617a4 (starting kit), 617a5 (hidden and locked), 617c3, 617c4,
  617e3 (chests and nodes).

The tables (characters database, `sql/basic/db_characters.src/04-buddy-roster`):
`buddy_clan` (owner -> companion account, clan guild) and `buddy_roster`
(owner and slot -> buddy character, class, race, talent shape, role). The
Lua side (`src/lua-basic/`) writes a player's choice into the roster; this
module reads it and makes the character.
