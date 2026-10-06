--------------------------------------------------------------------------------
-- gearset-command.lua (issue 617r)
--
-- For a general audience: gearset profiles are named lists of gear
-- (data/gearsets/<name>.lua; lib/gearsets.lua finds a character's record
-- in one by spec, or class, and race). A game master puts one on with
--
--     .gearset <profile> <character>           that character
--     .gearset <profile> buddies <partner>     every buddy of that partner
--     .elite <partner>                         short for: .gearset elite buddies <partner>
--
-- (or the same without the dot on the server console). For each one in the
-- world: what it wears in each of the record's slots is destroyed and the
-- record's item equipped, after teaching any weapon or armour proficiency
-- the item needs; the record's bags go into empty bag slots (a bag already
-- worn is never taken off: it may hold things); its ammunition is added.
-- Someone with no record in the profile is named and left as they are,
-- never given a near match. Shirt and tabard are never touched.
--
-- This was the elite-only ".elite" command (elite-outfits.lua, 2026-10-04,
-- first used to dress Growth's party); it became the general gearset
-- command on 2026-10-05 (owner: "able to be referenced by certain chat
-- commands. The 'elite' group is just the first profile we made").
-- Checked offline by scripts/test-gearsets.
--------------------------------------------------------------------------------

local PLAYER_EVENT_ON_COMMAND = 42
local GM_RANK      = 2              -- game masters only
local OFF_HAND     = 16
local BAG_SLOTS    = { 19, 20, 21, 22 }
local TAG          = "[gearset] "

-- {{{ local function script_dir
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
-- }}}

local Gearsets = dofile(script_dir() .. "lib/gearsets.lua")
local TD       = dofile(script_dir() .. "data/buddy-talent-data.lua")
local PROFILES = script_dir() .. "data/gearsets/"

-- {{{ proficiencies
-- The game refuses an item its wearer has no proficiency for. Buddies made
-- straight at a high level miss the proficiencies a trainer teaches at 40
-- (Plate Mail, Mail) and every weapon master's lesson (2026-10-04: Growth's
-- warriors had no Plate Mail, bows or guns; Kilta no Mail; a gap in 617n).
-- So before an item goes on, the proficiency it needs is taught, and every
-- teaching is reported (it is a mend, not the design). Spell numbers
-- checked against Spell.dbc, 2026-10-04.
-- item class -> item subclass -> proficiency spell
local PROFICIENCY = {
    [2] = { [0] = 196, [1] = 197, [2] = 264, [3] = 266, [4] = 198, [5] = 199, [6] = 200,      -- weapons
            [7] = 201, [8] = 202, [10] = 227, [13] = 15590, [15] = 1180, [16] = 2567,
            [18] = 5011, [19] = 5009 },
    [4] = { [3] = 8737, [4] = 750, [6] = 9116 },                                                 -- mail, plate, shield
}
-- }}}

-- {{{ local function dress
-- Puts record `rec` on character `b`. Every listed slot is emptied first
-- (and the off hand too when the record holds nothing there, so a
-- two-hander can go in), remembering what was worn; then each item is
-- equipped, after teaching the proficiency it needs. A slot that still
-- refuses its item gets its old item back, so nothing is lost. Then bags
-- into empty bag slots, then ammunition. Returns items on, items wanted,
-- the refused slots, and the proficiencies taught.
local function dress(b, rec)
    local items = rec.items
    local was = {}                                   -- slot -> item entry worn before
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
                -- refused even so: put the old item back, if there was one
                refused[#refused + 1] = string.format("slot %d item %d%s", slot, item,
                    was[slot] and (b:EquipItem(was[slot], slot) and " (old item back on)" or " (old item LOST)") or "")
            end
        end
    end
    -- an off hand emptied for a two-hander that then didn't go on
    if was[OFF_HAND] and not items[OFF_HAND] and not b:GetEquippedItemBySlot(OFF_HAND) and not b:GetEquippedItemBySlot(15) then
        b:EquipItem(was[OFF_HAND], OFF_HAND)
    end
    -- bags: only into empty bag slots, in order
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
-- }}}

-- {{{ local function shape_of
-- A character's talent shape (1-10): a buddy's planned shape from its
-- roster row until it has spent its points (owner, 2026-10-05: "yes", use
-- the plan), then, like anyone else, the shape nearest the points it has
-- spent; shape 7 (one-third each) with none spent. Storing players'
-- shapes is 617r3; until then this works it out each time.
local function shape_of(b, class)
    local trees = TD.classes[class] and TD.classes[class].trees
    local per = trees and Gearsets.points_of(trees, function(s) return b:HasSpell(s) end) or { 0, 0, 0 }
    if per[1] + per[2] + per[3] > 0 then return Gearsets.nearest_shape(TD.classes[class].shapes, per) end
    local q = CharDBQuery("SELECT profile FROM buddy_roster WHERE buddy = " .. b:GetGUIDLow())
    if q and q:GetUInt32(0) > 0 then return q:GetUInt32(0) end
    return Gearsets.EVEN_SHAPE
end
-- }}}

-- {{{ local function dress_one
-- Finds `b`'s record in `profile` and dresses it; one report line (or
-- two, with a proficiency teaching) through `say`. Returns true when fully
-- dressed.
local function dress_one(b, profile, say)
    if b:IsDead() then
        -- the game lets no one dead change gear; nothing is taken off
        say(string.format("%s%s is dead: skipped (revive them, then run this again)", TAG, b:GetName()))
        return false
    end
    local who = { class = b:GetClass(), race = b:GetRace(), level = b:GetLevel() }
    who.shape = shape_of(b, who.class)
    local rec, why = Gearsets.record(profile, who)
    if not rec then
        -- a missing record, reported rather than filled with something close
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
-- }}}

-- {{{ local function for_buddies
-- Dresses every buddy of the partner called `partner` in `profile`.
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
-- }}}

-- {{{ local function on_command
-- Commands from a game master in game, or from the console (no player).
-- Returning false tells the server it was handled. Names are letters only
-- (matched below), so the query can't be bent; the game keeps names as
-- it shows them: capital first.
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
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
