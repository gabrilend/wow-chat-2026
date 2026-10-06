# 168 - Chromie, Keeper of Settings

## Status
- Created: 2026-10-04
- Phase: 1
- Priority: Medium
- Related: 617s (the compass formation: its first setting), 617b
  (Sargobras, the other talking helper)

## Origin

Verbatim, 2026-10-04, answering whether the formation's compass
directions are fixed to the world:

> yes fixed to the world, but dynamically adjusting. Maybe we could talk
> to Sargobras (or a second, assistant NPC) to enable or disable that
> behavior. Chromie?
>
> so that it'd give us config options to change for certain server
> behaviors.

## Current Behavior

Not built. Server behaviours are set in the server's configuration files
and the project's config patches (`config/patches/C*.sh`), per profile, by
the owner; a player can change none of them, and each buddy behaviour is
the same for everyone.

## Intended Behavior

Chromie, an assistant beside Sargobras, keeps a player's own settings:
talking to her lists the behaviours a player may switch for themself (and
their buddies), each with its current state, and choosing one switches it.
Settings are per character (characters database: character guid integer,
setting name text, value integer), read by the scripts and the buddy
module where each behaviour is decided. A setting not chosen keeps the
server's default.

First settings:
- **compass on or off** (617s): on, each buddy keeps its own compass
  place round the owner; off, each time a buddy reaches its waypoint it
  takes the nearest ring slot nobody has claimed (617s8). The bot
  module's stock follow is not offered. Owner, 2026-10-05: "I think we
  should do compass orientation, and nearest free waypoint. An on/off
  flag is easier to understand than 3 options, and players never
  understand...";
- whether the compass directions are fixed to the world or turn with the
  owner;
- the ring's radius (the same value `.buddy wider` / `.buddy closer`
  change, 617s4).

Server-wide settings stay with the owner's config patches; Chromie only
holds what a player may choose for themself.

## Suggested Implementation Steps

1. The settings table (an install step) and a small reader the Lua
   scripts and the buddy module both use.
2. Chromie: a creature (her stock look) in the Caverns of Time and in
   Shattrath City, her menu in Lua, one line per setting with its state.
3. The formation (617s) reads its two settings from her table.

## Open Questions

1. (Answered 2026-10-04) Where Chromie stands: "she should live in the
   caverns of time and shattrath city": two spawns, one in the Caverns of
   Time and one in Shattrath City.
2. Which other behaviours should a player be able to switch?
