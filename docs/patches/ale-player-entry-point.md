# Player Entry Point Patch (B055)

## Overview

Adds one Lua call to the Lua engine (mod-ale): `player:GetEntryPoint()`,
where the player joined the battleground, arena or dungeon-finder group
they are in. The game keeps that spot for every player who joins one
(`Player::SetEntryPoint`, called when a battleground or arena is joined, by
the dungeon finder, and by arena spectating) and sends the player back to it
when the match ends; until now no script could read it.

First use: on beta, a druid's Teleport: Moonglade cast in a battleground or
arena comes back to where they joined it (issue 211a,
`src/lua-beta/druid-moonglade.lua`, `Moonglade.wayBack`). Applied by
`patches/B055-ale-player-entry-point.sh` (beta's patch list).

## Files to Modify

### 1. `modules/mod-ale/src/LuaEngine/methods/PlayerMethods.h`

Inside the `LuaPlayer` namespace, before its closing `};` (the file's last
one), add:

```cpp
    /**
     * Where the [Player] joined the battleground, arena or dungeon-finder
     * group they are in: the spot the game sends them back to when it
     * ends (Player::GetEntryPoint). Nil when the game keeps none.
     *
     * @return table entryPoint : { mapId, x, y, z, o } or nil
     */
    int GetEntryPoint(lua_State* L, Player* player)
    {
        WorldLocation const& at = player->GetEntryPoint();
        if (at.GetMapId() == MAPID_INVALID)
        {
            ALE::Push(L);
            return 1;
        }
        lua_newtable(L);
        lua_pushinteger(L, at.GetMapId());
        lua_setfield(L, -2, "mapId");
        lua_pushnumber(L, at.GetPositionX());
        lua_setfield(L, -2, "x");
        lua_pushnumber(L, at.GetPositionY());
        lua_setfield(L, -2, "y");
        lua_pushnumber(L, at.GetPositionZ());
        lua_setfield(L, -2, "z");
        lua_pushnumber(L, at.GetOrientation());
        lua_setfield(L, -2, "o");
        return 1;
    }
```

`MAPID_INVALID` (from `Position.h`, which `Player.h` brings in) is the
value `SetEntryPoint` starts from before it records a spot, so a map of
`MAPID_INVALID` means none was recorded.

### 2. `modules/mod-ale/src/LuaEngine/LuaFunctions.cpp`

In the player method table, after the line

```cpp
    { "GetHomebind", &LuaPlayer::GetHomebind },
```

add

```cpp
    { "GetEntryPoint", &LuaPlayer::GetEntryPoint },
```

## Usage

```lua
local at = player:GetEntryPoint()
if at then
    player:Teleport(at.mapId, at.x, at.y, at.z, at.o)
end
```

## Build Instructions

The patch is applied before compiling and reverted after by the build
(`scripts/compile`, beta's patch list in `patches/patches.sh`). Checked
without a build by `scripts/test-source-patches <project> beta` (applies,
reverts, byte-identical) and `scripts/test-patched-syntax <project> beta`
(the patched files compile). The owner builds.
