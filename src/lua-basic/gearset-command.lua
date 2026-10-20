
local PLAYER_EVENT_ON_COMMAND = 42
local GM_RANK      = 2
local OFF_HAND     = 16
local BAG_SLOTS    = { 19, 20, 21, 22 }
local TAG          = "[gearset] "

local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local Gearsets = dofile(script_dir() .. "lib/gearsets.lua")
local TD       = dofile(script_dir() .. "data/buddy-talent-data.lua")
local PROFILES = script_dir() .. "data/gearsets/"

local PROFICIENCY = {
    [2] = { [0] = 196, [1] = 197, [2] = 264, [3] = 266, [4] = 198, [5] = 199, [6] = 200,
            [7] = 201, [8] = 202, [10] = 227, [13] = 15590, [15] = 1180, [16] = 2567,
            [18] = 5011, [19] = 5009 },
    [4] = { [3] = 8737, [4] = 750, [6] = 9116 },
}

local function dress(b, rec)
    local items = rec.items
    local was = {}
    for slot = 0, 17 do
        if items[slot] or slot == OFF_HAND then
            local worn = b:GetEquippedItemBySlot(slot)
            if worn then
                was[slot] = worn:GetEntry()
                b:RemoveItem(worn, worn:GetCount())
            end
        end
    end
    local on, want, refused, taught = 0, 0, {}, {}
    for slot = 0, 17 do
        local item = items[slot]
        if item then
            want = want + 1
            local t     = GetItemTemplate(item)
            local spell = t and PROFICIENCY[t:GetClass()] and PROFICIENCY[t:GetClass()][t:GetSubClass()]
            if spell and not b:HasSpell(spell) then
                b:LearnSpell(spell)
                taught[#taught + 1] = tostring(spell)
            end
            if b:EquipItem(item, slot) then
                on = on + 1
            else
                refused[#refused + 1] = string.format("slot %d item %d%s", slot, item,
                    was[slot] and (b:EquipItem(was[slot], slot) and " (old item back on)" or " (old item LOST)") or "")
            end
        end
    end
    if was[OFF_HAND] and not items[OFF_HAND] and not b:GetEquippedItemBySlot(OFF_HAND) and not b:GetEquippedItemBySlot(15) then
        b:EquipItem(was[OFF_HAND], OFF_HAND)
    end
    local free = {}
    for _, slot in ipairs(BAG_SLOTS) do if not b:GetEquippedItemBySlot(slot) then free[#free + 1] = slot end end
    for i, bag in ipairs(rec.bags or {}) do
        want = want + 1
        if free[i] and b:EquipItem(bag, free[i]) then on = on + 1
        else refused[#refused + 1] = string.format("bag %d (no empty bag slot, or refused)", bag) end
    end
    if rec.ammo then
        want = want + 1
        if b:AddItem(rec.ammo.item, rec.ammo.count) then on = on + 1
        else refused[#refused + 1] = string.format("ammo %d x%d (bags full?)", rec.ammo.item, rec.ammo.count) end
    end
    b:SaveToDB()
    return on, want, refused, taught
end

local function shape_of(b, class)
    local trees = TD.classes[class] and TD.classes[class].trees
    local per = trees and Gearsets.points_of(trees, function(s) return b:HasSpell(s) end) or { 0, 0, 0 }
    if per[1] + per[2] + per[3] > 0 then return Gearsets.nearest_shape(TD.classes[class].shapes, per) end
    local q = CharDBQuery("SELECT profile FROM buddy_roster WHERE buddy = " .. b:GetGUIDLow())
    if q and q:GetUInt32(0) > 0 then return q:GetUInt32(0) end
    return Gearsets.EVEN_SHAPE
end

local function dress_one(b, profile, say)
    if b:IsDead() then
        say(string.format("%s%s is dead: skipped (revive them, then run this again)", TAG, b:GetName()))
        return false
    end
    local who = { class = b:GetClass(), race = b:GetRace(), level = b:GetLevel() }
    who.shape = shape_of(b, who.class)
    local rec, why = Gearsets.record(profile, who)
    if not rec then
        say(string.format("%s%s (race %d, class %d, shape %s, level %d): %s in %s; add one to data/gearsets/%s.lua",
            TAG, b:GetName(), who.race, who.class, tostring(who.shape), who.level, why, profile.name, profile.name))
        return false
    end
    local on, want, refused, taught = dress(b, rec)
    if #taught > 0 then
        say(string.format("%s%s lacked proficiencies (a buddy-making gap, 617n); taught spells %s",
            TAG, b:GetName(), table.concat(taught, ", ")))
    end
    say(string.format("%s%s wears %s: %d of %d%s", TAG, b:GetName(), profile.name, on, want,
        #refused > 0 and ("; refused: " .. table.concat(refused, ", ") ..
        " (to debug: is the slot right for the item? can this class use it? scripts/test-gearsets)") or ""))
    return #refused == 0
end

local function for_buddies(profile, partner, say)
    local q = CharDBQuery(string.format(
        "SELECT r.slot, r.buddy FROM buddy_roster r JOIN characters c ON c.guid = r.owner " ..
        "WHERE c.name = '%s' AND r.buddy <> 0 ORDER BY r.slot", partner))
    if not q then
        return say(string.format("%s%s has no buddies in the roster (no such character, or none chosen yet)", TAG, partner))
    end
    local dressed, total = 0, 0
    repeat
        total = total + 1
        local slot, guid = q:GetUInt32(0), q:GetUInt32(1)
        local b = GetPlayerByGUID(GetPlayerGUID(guid))
        if not b or not b:IsInWorld() then
            say(string.format("%sslot %d (character %d): not in the world, skipped", TAG, slot, guid))
        elseif dress_one(b, profile, say) then
            dressed = dressed + 1
        end
    until not q:NextRow()
    say(string.format("%s%s: %d of %d buddies fully dressed in %s", TAG, partner, dressed, total, profile.name))
end

local function on_command(event, player, command, handler)
    local name, buddies, who
    local partner = command:match("^elite%s+(%a+)%s*$")
    if partner then
        name, buddies, who = "elite", true, partner
    else
        name, who = command:match("^gearset%s+([%w%-]+)%s+buddies%s+(%a+)%s*$")
        buddies = name ~= nil
        if not name then name, who = command:match("^gearset%s+([%w%-]+)%s+(%a+)%s*$") end
    end
    if not name then return end
    if player and player:GetGMRank() < GM_RANK then return end
    local say = player and function(text) player:SendBroadcastMessage(text) end
                        or function(text) handler:SendSysMessage(text) end
    local ok, profile = pcall(Gearsets.load, PROFILES, name)
    if not ok then say(TAG .. tostring(profile)); return false end
    who = who:sub(1, 1):upper() .. who:sub(2):lower()
    if buddies then
        for_buddies(profile, who, say)
    else
        local p = GetPlayerByName(who)
        if not p or not p:IsInWorld() then say(string.format("%s%s is not in the world", TAG, who))
        else dress_one(p, profile, say) end
    end
    return false
end

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
