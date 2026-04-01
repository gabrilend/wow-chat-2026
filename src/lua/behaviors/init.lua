-- {{{ Everland Ghostsong - Behavior System Initialization
-- Loads all behavior modules in dependency order
-- This file should be required by the main Lua entry point
--
-- Issue: 133-gesture-command-system-kneel-convoy.md
-- Concept Catalog: 001-010, 101-139
-- }}}

print("[Behaviors] Initializing behavior system...")

-- {{{ Load order (dependency-aware)
-- 1. Base utilities (no dependencies)
-- 2. Core behaviors (depend on movement only)
-- 3. Complex behaviors (depend on core behaviors)
-- }}}

-- {{{ Group 1: Base utilities
require("movement")
print("[Behaviors] Loaded: movement")
-- }}}

-- {{{ Group 2: Core behaviors
-- avoid-monsters is required by sit-and-rest and orbit-player
require("behaviors/avoid-monsters")
print("[Behaviors] Loaded: avoid-monsters")
-- }}}

-- {{{ Group 3: Combat and survival behaviors
require("behaviors/find-monsters")
print("[Behaviors] Loaded: find-monsters")

require("behaviors/sit-and-rest")
print("[Behaviors] Loaded: sit-and-rest")
-- }}}

-- {{{ Group 4: Formation and movement behaviors
require("behaviors/orbit-player")
print("[Behaviors] Loaded: orbit-player")
-- }}}

-- {{{ Group 5: Gesture and social behaviors
require("behaviors/gestures")
print("[Behaviors] Loaded: gestures")

require("behaviors/convoy")
print("[Behaviors] Loaded: convoy")
-- }}}

-- {{{ Group 6: Affinity and consensus behaviors
require("behaviors/level-affinity")
print("[Behaviors] Loaded: level-affinity")

require("behaviors/zone-consensus")
print("[Behaviors] Loaded: zone-consensus")
-- }}}

-- {{{ Behavior registry
-- Allows other scripts to check which behaviors are loaded
Behaviors = {
    version = "1.0.0",
    loaded = {
        movement = true,
        avoid_monsters = true,
        find_monsters = true,
        sit_and_rest = true,
        orbit_player = true,
        gestures = true,
        convoy = true,
        level_affinity = true,
        zone_consensus = true
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
