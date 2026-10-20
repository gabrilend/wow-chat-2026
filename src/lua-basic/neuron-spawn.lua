
NeuronSpawn = {}

NeuronSpawn.GROUND_TOLERANCE =   40
NeuronSpawn.PROBE_HEIGHT     =   10
NeuronSpawn.CORPSE_DESPAWN   =  300

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
end
