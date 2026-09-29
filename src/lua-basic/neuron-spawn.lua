---------------------------------------------------------------------------------------------------
-- neuron-spawn.lua
--
-- One reusable, ground-probed creature placement, callable by name from any
-- resident Lua script -- including, eventually, the one-shot scripts
-- ../wow-chat-neuron/src/049-spawn.lua writes into this same directory
-- every time its world.spawn operation runs (issue 162).
--
-- NOT WIRED TO NEURON YET. neuron's Spawn.script still generates its own
-- copy of this exact sequence inline, on purpose: ALE's custom script
-- directory is symlinked strictly per profile
-- (patches/E-patches.sh, patch_E001_lua_script_symlinks -- LUA_SRC is
-- src/lua-${PROFILE}, never shared), and this file currently lives only
-- under lua-basic. The active profile recorded in .profile is "vanilla",
-- whose own Lua directory does not load this file. Pointing neuron's
-- generator at NeuronSpawn.at before that is resolved would make a tested
-- operation (world.spawn) depend on a global that is silently absent under
-- the profile neuron is actually configured to act on. See issue 162's
-- Open Questions.
--
-- UNVERIFIED, same as the file it mirrors: no session that touched either
-- has had a worldserver up. The math and the refusal condition are copied
-- from Spawn.script exactly (same GetHeight probe offset, same 40-yard
-- tolerance, same PerformIngameSpawn argument order) specifically so the
-- two can be compared line for line rather than trusted to agree by
-- description.
---------------------------------------------------------------------------------------------------

NeuronSpawn = {} -- table to hold the functions.

-- {{{ Configuration
NeuronSpawn.GROUND_TOLERANCE =   40  -- yards; beyond this, "no ground" (water, a hole)
NeuronSpawn.PROBE_HEIGHT     =   10  -- yards above z to probe from, so the ray finds the floor
NeuronSpawn.CORPSE_DESPAWN   =  300  -- seconds; matches world.spawn's own default
-- }}}

-- {{{ NeuronSpawn.at
-- Place one creature at (x, y, z) on mapId, reading the real ground height
-- rather than trusting the caller's z. Refuses (returns nil, logs why)
-- rather than dropping a creature into open water or a hole in the terrain
-- -- a spawn that silently fails to appear is a spawn that looks exactly
-- like nothing having happened.
--
--   entry        creature_template entry number (int) -- from world.creatures,
--                never a name; several hundred rows share a name.
--   mapId        the map to spawn on (int)
--   x, y, z      target position (floats); z is where the CALLER believes
--                the ground is -- ambush.lua's spawn functions and
--                neuron's place book both produce a z this way, and this
--                function is the one place that checks it against the map
--   orientation  facing, in radians (float)
--   permanent    boolean; false (the default meaning) despawns the spawn
--                point when the worldserver next stops
--
-- Returns the spawned creature object, or nil if refused.
function NeuronSpawn.at(entry, mapId, x, y, z, orientation, permanent)
    local map    = GetMapById(mapId)
    local ground = map and map:GetHeight(x, y, z + NeuronSpawn.PROBE_HEIGHT) or nil

    if not ground or math.abs(ground - z) > NeuronSpawn.GROUND_TOLERANCE then
        print(string.format(
            "[NeuronSpawn] refused: no ground at %.1f,%.1f on map %d", x, y, mapId))
        return nil
    end

    local creature = PerformIngameSpawn(1, entry, mapId, 0, x, y, ground,
        orientation, permanent and true or false, NeuronSpawn.CORPSE_DESPAWN)

    print(string.format("[NeuronSpawn] placed %d at %.1f,%.1f", entry, x, y))
    return creature
end -- }}}
