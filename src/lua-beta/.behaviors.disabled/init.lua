
print("[Behaviors] Initializing behavior registry (scripts already loaded by ALE)...")

Behaviors = {
    version = "1.1.0",
    loaded = {
        movement       = true,
        avoid_monsters = true,
        find_monsters  = true,
        sit_and_rest   = true,
        orbit_player   = true,
        gestures       = true,
        convoy         = true,
        level_affinity = true,
        zone_consensus = true,
        dungeon_rails  = true,
        bot_wander     = true
    }
}

function Behaviors.isLoaded(name)
    return Behaviors.loaded[name] == true
end

function Behaviors.getLoadedCount()
    local count = 0
    for _, _ in pairs(Behaviors.loaded) do
        count = count + 1
    end
    return count
end

print("[Behaviors] System initialized - " .. Behaviors.getLoadedCount() .. " behaviors loaded")
