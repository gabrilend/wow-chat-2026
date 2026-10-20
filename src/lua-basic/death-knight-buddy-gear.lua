
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local PLAYER_EVENT_ON_LOGIN          = 3
local PLAYER_EVENT_ON_COMPLETE_QUEST = 54
local CLASS_DEATH_KNIGHT             = 6
local RUNEBLADE                      = 38707
local SLOT_MAIN_HAND                 = 15
local DRESS_AFTER_LOGIN_MS           = 10000
local DRESS_AFTER_QUEST_MS           = 3000
local GREEN_LEVELS_BELOW             = 4
local RUNEBLADE_SLOTS                = { [1] = true, [2] = true }
local LIGHT_OF_DAWN                  = 12801
local TAG                            = "[death-knight-buddy-gear] "

local DK_STORY = dofile(script_dir() .. "data/death-knight-skip-quests.lua")

local PLACES = {
    [1] = { 0 },  [2] = { 1 },  [3] = { 2 },  [5] = { 4 },  [20] = { 4 },
    [6] = { 5 },  [7] = { 6 },  [8] = { 7 },  [9] = { 8 },  [10] = { 9 },
    [11] = { 10, 11 }, [12] = { 12, 13 }, [16] = { 14 },
    [17] = { 15 }, [13] = { 15 }, [21] = { 15 }, [22] = { 16 }, [14] = { 16 },
    [28] = { 17 },
}

local STORY_GEAR, KIND = {}, {}
do
    local ids = {}
    for _, q in ipairs(DK_STORY) do ids[#ids + 1] = q[1] end
    local by_quest = {}
    local q = WorldDBQuery("SELECT ID, RewardItem1, RewardItem2, RewardItem3, RewardItem4, RewardChoiceItemID1,"
        .. " RewardChoiceItemID2, RewardChoiceItemID3, RewardChoiceItemID4, RewardChoiceItemID5, RewardChoiceItemID6"
        .. " FROM quest_template WHERE ID IN (" .. table.concat(ids, ",") .. ")")
    if q then
        repeat
            local items, choices = {}, {}
            for c = 1, 4 do local e = q:GetUInt32(c) if e ~= 0 then items[#items + 1] = e end end
            for c = 5, 10 do local e = q:GetUInt32(c) if e ~= 0 then choices[#choices + 1] = e end end
            by_quest[q:GetUInt32(0)] = { items = items, choices = choices }
        until not q:NextRow()
    end
    local all = {}
    for _, s in ipairs(DK_STORY) do
        local g = by_quest[s[1]] or { items = {}, choices = {} }
        STORY_GEAR[#STORY_GEAR + 1] = { quest = s[1], races = s[2], items = g.items, choices = g.choices }
        for _, e in ipairs(g.items) do all[#all + 1] = e end
        for _, e in ipairs(g.choices) do all[#all + 1] = e end
    end
    if #all > 0 then
        local k = WorldDBQuery("SELECT entry, InventoryType FROM item_template WHERE entry IN (" .. table.concat(all, ",") .. ")")
        if k then repeat KIND[k:GetUInt32(0)] = k:GetUInt32(1) until not k:NextRow() end
    end
end

local function pick(list, buddy_low, salt)
    if #list == 0 then return nil end
    return list[(buddy_low * 31 + salt) % #list + 1]
end

local greens_by_level = {}
local function green_weapons(level)
    if greens_by_level[level] then return greens_by_level[level] end
    local list = {}
    local q = WorldDBQuery(string.format("SELECT entry FROM item_template WHERE class = 2 AND subclass IN (1, 5, 6, 8)"
        .. " AND Quality = 2 AND InventoryType = 17 AND RequiredLevel BETWEEN %d AND %d"
        .. " AND (AllowableClass = -1 OR AllowableClass & 32 <> 0) ORDER BY entry", level - GREEN_LEVELS_BELOW, level))
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    greens_by_level[level] = list
    return list
end

local function wanted_gear(buddy, owner, slot_in_roster, skipped)
    local low, want = buddy:GetGUIDLow(), {}
    if not skipped then
        local mask = owner:GetRaceMask()
        for _, g in ipairs(STORY_GEAR) do
            if (g.races == 0 or bit.band(g.races, mask) ~= 0) and owner:GetQuestRewardStatus(g.quest) then
                local items = {}
                for _, e in ipairs(g.items) do items[#items + 1] = e end
                local c = pick(g.choices, low, g.quest)
                if c then items[#items + 1] = c end
                for _, e in ipairs(items) do
                    local places = PLACES[KIND[e] or 0]
                    if places then
                        local place = places[1]
                        if places[2] and want[places[1]] and want[places[1]] ~= e then place = places[2] end
                        want[place] = e
                    end
                end
            end
        end
    end
    if RUNEBLADE_SLOTS[slot_in_roster] then
        want[SLOT_MAIN_HAND] = RUNEBLADE
    elseif skipped or not owner:GetQuestRewardStatus(LIGHT_OF_DAWN) then
        local w = pick(green_weapons(buddy:GetLevel()), low, 0)
        if w then want[SLOT_MAIN_HAND] = w
        else print(string.format("%sERROR: no green two-handed weapon for a level-%d death knight; %s keeps its kit's",
            TAG, buddy:GetLevel(), buddy:GetName())) end
    end
    return want
end

local function dress(buddy, owner, slot_in_roster, skipped)
    local put, refused = 0, {}
    for place, entry in pairs(wanted_gear(buddy, owner, slot_in_roster, skipped)) do
        local worn = buddy:GetEquippedItemBySlot(place)
        if not worn or worn:GetEntry() ~= entry then
            if worn then buddy:RemoveItem(worn, worn:GetCount()) end
            if buddy:EquipItem(entry, place) then put = put + 1 else refused[#refused + 1] = entry .. "@" .. place end
        end
    end
    if #refused > 0 then
        print(string.format("%sERROR: %s (level %d) could not wear %s (item@place); %d others put on",
            TAG, buddy:GetName(), buddy:GetLevel(), table.concat(refused, ", "), put))
    end
end

local function owner_and_slot(buddy)
    if buddy:GetClass() ~= CLASS_DEATH_KNIGHT then return nil end
    local q = CharDBQuery("SELECT owner, slot FROM buddy_roster WHERE buddy = " .. buddy:GetGUIDLow())
    if not q then return nil end
    local owner = GetPlayerByGUID(GetPlayerGUID(q:GetUInt32(0)))
    if not owner or owner:GetClass() ~= CLASS_DEATH_KNIGHT then return nil end
    local s = CharDBQuery("SELECT skipped FROM basic_718_souls WHERE dk = " .. q:GetUInt32(0))
    return owner, q:GetUInt32(1), s and s:GetUInt32(0) == 1
end

local function on_login(event, player)
    player:RegisterEvent(function(_, _, _, b)
        local owner, slot, skipped = owner_and_slot(b)
        if owner then dress(b, owner, slot, skipped) end
    end, DRESS_AFTER_LOGIN_MS, 1)
end

local due = {}
local function on_complete_quest(event, player, quest)
    if player:GetClass() ~= CLASS_DEATH_KNIGHT then return end
    local low = player:GetGUIDLow()
    if due[low] then return end
    due[low] = true
    player:RegisterEvent(function(_, _, _, p)
        due[p:GetGUIDLow()] = nil
        local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. p:GetGUIDLow() .. " AND buddy <> 0")
        if not q then return end
        repeat
            local b = GetPlayerByGUID(GetPlayerGUID(q:GetUInt32(0)))
            if b then
                local owner, slot, skipped = owner_and_slot(b)
                if owner then dress(b, owner, slot, skipped) end
            end
        until not q:NextRow()
    end, DRESS_AFTER_QUEST_MS, 1)
end

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, on_login)
RegisterPlayerEvent(PLAYER_EVENT_ON_COMPLETE_QUEST, on_complete_quest)
