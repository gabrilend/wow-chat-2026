--------------------------------------------------------------------------------
-- elite-outfits.lua (issue 617r)
--
-- For a general audience: elites are full outfits for buddy types, the
-- bannermen of the Horde and the Alliance (data/elite-outfit-profiles.lua; every
-- item there is checked against the world database by
-- scripts/test-elite-outfits). A game master types
--
--     .elite <partner name>
--
-- (or runs "elite <partner name>" on the server console) and each of that
-- partner's buddies who is in the world is dressed in the elite for its
-- race, class and role: what it wears in each of the elite's slots is
-- destroyed and the elite's item equipped. A buddy with no matching elite
-- is named and left as it is, never given a near match. Shirt and tabard
-- are never touched.
--
-- First used for Growth's party (owner, 2026-10-04: "equip Growth's
-- buddy-bots with gear that is roughly equivalent ... nothing beyond Molten
-- Core").
--------------------------------------------------------------------------------

local PLAYER_EVENT_ON_COMMAND = 42
local GM_RANK      = 2              -- game masters only
local OFF_HAND     = 16
local TAG          = "[elite] "

-- {{{ local function script_dir
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
-- }}}

local ELITES = dofile(script_dir() .. "data/elite-outfit-profiles.lua")

-- race, class, role -> the elite's name; one index instead of a search
local by_type = {}
for name, e in pairs(ELITES) do by_type[e.race * 10000 + e.class * 100 + e.role] = name end

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
-- Puts elite `name` on buddy `b`. Every listed slot is emptied first (and
-- the off hand too when the elite holds nothing there, so a two-hander can
-- go in), remembering what was worn; then each item is equipped, after
-- teaching the proficiency it needs. A slot that still refuses its item
-- gets its old item back, so nothing is lost. Returns how many went on,
-- the refused slots, and the proficiencies taught.
local function dress(b, name)
    local items = ELITES[name].items
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
    local on, refused, taught = 0, {}, {}
    for slot = 0, 17 do
        local item = items[slot]
        if item then
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
    b:SaveToDB()
    return on, refused, taught
end
-- }}}

-- {{{ local function elite_for_partner
-- Dresses every buddy of the partner called `partner`; `say` prints a line
-- back to whoever asked.
local function elite_for_partner(partner, say)
    local q = CharDBQuery(string.format(
        "SELECT r.slot, r.buddy, r.race, r.class, r.role FROM buddy_roster r JOIN characters c ON c.guid = r.owner " ..
        "WHERE c.name = '%s' AND r.buddy <> 0 ORDER BY r.slot", partner))
    if not q then
        return say(string.format("%s%s has no buddies in the roster (no such character, or none chosen yet)", TAG, partner))
    end
    local dressed, total = 0, 0
    repeat
        total = total + 1
        local slot, guid = q:GetUInt32(0), q:GetUInt32(1)
        local race, class, role = q:GetUInt32(2), q:GetUInt32(3), q:GetUInt32(4)
        local b    = GetPlayerByGUID(GetPlayerGUID(guid))
        local name = by_type[race * 10000 + class * 100 + role]
        if not b or not b:IsInWorld() then
            say(string.format("%sslot %d (character %d): not in the world, skipped", TAG, slot, guid))
        elseif b:IsDead() then
            -- the game lets no one dead change gear; nothing is taken off
            say(string.format("%s%s is dead: skipped (revive them, then run this again)", TAG, b:GetName()))
        elseif not name then
            -- no elite for this race, class and role yet: a missing profile,
            -- reported rather than filled with something close
            say(string.format("%s%s (race %d, class %d, role %d): no elite for this type yet; add one to data/elite-outfit-profiles.lua",
                TAG, b:GetName(), race, class, role))
        else
            local on, refused, taught = dress(b, name)
            local want = 0
            for _ in pairs(ELITES[name].items) do want = want + 1 end
            if #refused == 0 then dressed = dressed + 1 end
            if #taught > 0 then
                say(string.format("%s%s lacked proficiencies (a buddy-making gap, 617n); taught spells %s",
                    TAG, b:GetName(), table.concat(taught, ", ")))
            end
            say(string.format("%s%s wears %s: %d of %d items%s", TAG, b:GetName(), name, on, want,
                #refused > 0 and ("; refused: " .. table.concat(refused, ", ") ..
                " (to debug: is the slot right for the item? can this class use it? scripts/test-elite-outfits)") or ""))
        end
    until not q:NextRow()
    say(string.format("%s%s: %d of %d buddies fully dressed", TAG, partner, dressed, total))
end
-- }}}

-- {{{ local function on_command
-- ".elite <name>" from a game master in game, or "elite <name>" from the
-- console (no player). Returning false tells the server it was handled.
local function on_command(event, player, command, handler)
    local partner = command:match("^elite%s+(%a+)%s*$")
    if not partner then return end
    if player and player:GetGMRank() < GM_RANK then return end
    local say = player and function(text) player:SendBroadcastMessage(text) end
                        or function(text) handler:SendSysMessage(text) end
    -- names are letters only (matched above), so the query can't be bent;
    -- the roster keeps the name as the game shows it: capital first
    elite_for_partner(partner:sub(1, 1):upper() .. partner:sub(2):lower(), say)
    return false
end
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
