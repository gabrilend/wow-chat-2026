-- {{{ Everland Ghostsong - Behavior System Initialization
-- ALE auto-loads all .lua files from subdirectories via dofile-style loading.
-- This init.lua file only sets up the behavior registry - the actual behavior
-- scripts are already loaded by ALE before this file runs.
--
-- Issue: 133-gesture-command-system-kneel-convoy.md
-- Issue: 332 - Removed require() calls that caused double-loading/registry corruption
-- Concept Catalog: 001-010, 101-139
-- }}}

print("[Behaviors] Initializing behavior registry (scripts already loaded by ALE)...")

-- {{{ Behavior registry
-- Allows other scripts to check which behaviors are loaded
Behaviors = {
    version = "1.1.0",  -- Updated for issue 611/612
    loaded = {
        movement       = true,
        avoid_monsters = true,
        find_monsters  = true,
        sit_and_rest   = true,
        orbit_player   = true,
        gestures       = true,
        convoy         = true,
        level_affinity = true,  -- legacy, kept for utilities
        zone_consensus = true,  -- legacy, kept for utilities
        dungeon_rails  = true,  -- issue 612
        bot_wander     = true   -- issue 611
    }
}
-- }}}

-- {{{ Behaviors.isLoaded
-- Check if a specific behavior is loaded
function Behaviors.isLoaded(name)
    return Behaviors.loaded[name] == true
end
-- }}}

-- {{{ Behaviors.getLoadedCount
-- Get count of loaded behaviors
function Behaviors.getLoadedCount()
    local count = 0
    for _, _ in pairs(Behaviors.loaded) do
        count = count + 1
    end
    return count
end
-- }}}

print("[Behaviors] System initialized - " .. Behaviors.getLoadedCount() .. " behaviors loaded")
