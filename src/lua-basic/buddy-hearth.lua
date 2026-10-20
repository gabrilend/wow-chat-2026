
local PLAYER_EVENT_ON_SPELL_CAST = 5
local HEARTH_SPELLS = { [8690] = true,
                        [556]  = true }
local HEARTH_FOLLOW_MS = 1500
local CURRENT_GENERIC_SPELL, CURRENT_CHANNELED_SPELL = 1, 3
local TAG = "[buddy-hearth] "

local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local Arc = dofile(script_dir() .. "lib/buddy-arc.lua")

local function roster_of(partner_low)
    local list = {}
    local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. partner_low .. " AND buddy <> 0 ORDER BY slot")
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    return list
end

local function place_round(partner_low, which, map, x, y, z, o)
    local roster = roster_of(partner_low)
    local spots = Arc.places(x, y, o, #roster, "centre")
    local moved = 0
    for i, guid in ipairs(roster) do
        if not which or which == guid then
            local b = GetPlayerByGUID(GetPlayerGUID(guid))
            if b and b:IsInWorld() then
                b:InterruptSpell(CURRENT_GENERIC_SPELL)
                b:InterruptSpell(CURRENT_CHANNELED_SPELL)
                b:Teleport(map, spots[i].x, spots[i].y, z, spots[i].o)
                moved = moved + 1
            end
        end
    end
    return moved, #roster
end

local function on_spell_cast(event, player, spell)
    if not HEARTH_SPELLS[spell:GetEntry()] then return end
    local low = player:GetGUIDLow()
    local owner = CharDBQuery("SELECT owner FROM buddy_roster WHERE buddy = " .. low)
    if owner then
        local partner_low = owner:GetUInt32(0)
        player:RegisterEvent(function(_, _, _, b)
            local partner = GetPlayerByGUID(GetPlayerGUID(partner_low))
            if not partner then return end
            local home = partner:GetHomebind()
            place_round(partner_low, low, home.mapId, home.x, home.y, home.z, 0)
        end, HEARTH_FOLLOW_MS, 1)
        return
    end
    if #roster_of(low) == 0 then return end
    player:RegisterEvent(function(_, _, _, p)
        local home = p:GetHomebind()
        local x, y, z, o = p:GetLocation()
        if p:GetMapId() ~= home.mapId then
            x, y, z, o = home.x, home.y, home.z, 0
        end
        local moved, total = place_round(p:GetGUIDLow(), nil, home.mapId, x, y, z, o)
        if moved < total then
            print(string.format("%s%s hearthed: %d of %d buddies moved with them (the rest are not in the world)", TAG, p:GetName(), moved, total))
        end
    end, HEARTH_FOLLOW_MS, 1)
end

RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, on_spell_cast)
