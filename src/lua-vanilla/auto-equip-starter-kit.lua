
local PLAYER_EVENT_ON_FIRST_LOGIN = 30

local BAG_ALL              = 255
local EQUIPPED_SLOT_START  =  0
local EQUIPPED_SLOT_END    = 18
local BAG_SLOT_START       = 19
local BAG_SLOT_END         = 22
local BACKPACK_SLOT_START  = 23
local BACKPACK_SLOT_END    = 38

local SLOT_HEAD       =  0
local SLOT_NECK       =  1
local SLOT_SHOULDERS  =  2
local SLOT_BODY       =  3
local SLOT_CHEST      =  4
local SLOT_WAIST      =  5
local SLOT_LEGS       =  6
local SLOT_FEET       =  7
local SLOT_WRISTS     =  8
local SLOT_HANDS      =  9
local SLOT_FINGER1    = 10
local SLOT_TRINKET1   = 12
local SLOT_BACK       = 14
local SLOT_MAINHAND   = 15
local SLOT_OFFHAND    = 16
local SLOT_RANGED     = 17

local SLOT_BY_INVTYPE = {
    [ 1] = SLOT_HEAD,        [ 2] = SLOT_NECK,        [ 3] = SLOT_SHOULDERS,
    [ 4] = SLOT_BODY,        [ 5] = SLOT_CHEST,       [ 6] = SLOT_WAIST,
    [ 7] = SLOT_LEGS,        [ 8] = SLOT_FEET,        [ 9] = SLOT_WRISTS,
    [10] = SLOT_HANDS,       [11] = SLOT_FINGER1,     [12] = SLOT_TRINKET1,
    [13] = SLOT_MAINHAND,    [14] = SLOT_OFFHAND,     [15] = SLOT_RANGED,
    [16] = SLOT_BACK,        [17] = SLOT_MAINHAND,    [20] = SLOT_CHEST,
    [21] = SLOT_MAINHAND,    [22] = SLOT_OFFHAND,     [23] = SLOT_OFFHAND,
    [25] = SLOT_RANGED,      [26] = SLOT_RANGED,      [28] = SLOT_RANGED,
}

local INVTYPE_IS_ONE_HAND = { [13] = true, [21] = true }

local ITEM_CLASS_WEAPON     =  2
local ITEM_CLASS_CONTAINER  =  1
local ITEM_CLASS_PROJECTILE =  6
local ITEM_CLASS_QUIVER     = 11
local HEARTHSTONE_ENTRY     = 6948

local HEARTH_BY_RACE = {
    [1]  = { x =  -3827.93, y =   -831.9,  z =  10.09, mapId = 0, areaId =  38 },
    [2]  = { x =  -1050.04, y =  -3664.8,  z =  23.97, mapId = 1, areaId =  17 },
    [3]  = { x =  -3827.93, y =   -831.9,  z =  10.09, mapId = 0, areaId =  38 },
    [4]  = { x =   2781.16, y =   -433.0,  z = 116.67, mapId = 1, areaId = 331 },
    [5]  = { x =     -5.97, y =  -942.28,  z =  57.16, mapId = 0, areaId = 267 },
    [6]  = { x =    893.65, y =   927.95,  z = 106.36, mapId = 1, areaId = 406 },
    [7]  = { x =   2781.16, y =   -433.0,  z = 116.67, mapId = 1, areaId = 331 },
    [8]  = { x =     -5.97, y =  -942.28,  z =  57.16, mapId = 0, areaId = 267 },
    [10] = { x =    893.65, y =   927.95,  z = 106.36, mapId = 1, areaId = 406 },
    [11] = { x = -10516.0,  y = -1161.21,  z =  28.12, mapId = 0, areaId =  10 },
}

local function build_kit_query(race, class)
    return string.format([[
        SELECT pci.itemid, pci.amount, it.InventoryType, it.class, it.subclass
        FROM playercreateinfo_item pci
        JOIN item_template it ON it.entry = pci.itemid
        WHERE pci.race = %d AND pci.class = %d
          AND pci.Note LIKE 'vanilla-148h-%%'
        ORDER BY pci.itemid]], race, class)
end

local function collect_kit_rows(query)
    local rows = {}
    if not query then return rows end
    repeat
        table.insert(rows, {
            entry    = query:GetUInt32(0),
            amount   = query:GetUInt32(1),
            invType  = query:GetUInt32(2),
            class    = query:GetUInt32(3),
            subclass = query:GetUInt32(4),
        })
    until not query:NextRow()
    return rows
end

local function categorize_kit(rows)
    local buckets = { bags = {}, quiver = {}, ammo = {}, hearth = {}, equip = {} }
    for _, row in ipairs(rows) do
        if row.entry == HEARTHSTONE_ENTRY then
            table.insert(buckets.hearth, row)
        elseif row.class == ITEM_CLASS_CONTAINER then
            table.insert(buckets.bags, row)
        elseif row.class == ITEM_CLASS_QUIVER then
            table.insert(buckets.quiver, row)
        elseif row.class == ITEM_CLASS_PROJECTILE then
            table.insert(buckets.ammo, row)
        else
            table.insert(buckets.equip, row)
        end
    end
    return buckets
end

local function strip_all_inventory(player)
    for slot = EQUIPPED_SLOT_START, EQUIPPED_SLOT_END do
        local item = player:GetEquippedItemBySlot(slot)
        if item then player:RemoveItem(item, item:GetCount()) end
    end
    for slot = BAG_SLOT_START, BAG_SLOT_END do
        local item = player:GetItemByPos(BAG_ALL, slot)
        if item then player:RemoveItem(item, item:GetCount()) end
    end
    for slot = BACKPACK_SLOT_START, BACKPACK_SLOT_END do
        local item = player:GetItemByPos(BAG_ALL, slot)
        if item then player:RemoveItem(item, item:GetCount()) end
    end
end

local function first_empty_bag_slot(player)
    for slot = BAG_SLOT_START, BAG_SLOT_END do
        if player:GetItemByPos(BAG_ALL, slot) == nil then
            return slot
        end
    end
    return nil
end

local function install_containers(player, rows)
    for _, row in ipairs(rows) do
        for _ = 1, row.amount do
            local bag = player:AddItem(row.entry, 1)
            if bag then
                local target = first_empty_bag_slot(player)
                if target then
                    player:EquipItem(bag, target)
                end
            end
        end
    end
end

local function install_equipment(player, rows)
    for _, row in ipairs(rows) do
        for _ = 1, row.amount do
            local item = player:AddItem(row.entry, 1)
            if item then
                local target = SLOT_BY_INVTYPE[row.invType]
                if target then
                    if INVTYPE_IS_ONE_HAND[row.invType] then
                        if player:GetEquippedItemBySlot(SLOT_MAINHAND) == nil then
                            player:EquipItem(item, SLOT_MAINHAND)
                        elseif player:GetEquippedItemBySlot(SLOT_OFFHAND) == nil then
                            player:EquipItem(item, SLOT_OFFHAND)
                        end
                    else
                        player:EquipItem(item, target)
                    end
                end
            end
        end
    end
end

local function install_ammo(player, rows)
    for _, row in ipairs(rows) do
        player:AddItem(row.entry, row.amount)
    end
end

local function install_hearthstone(player, rows)
    for _, row in ipairs(rows) do
        player:AddItem(row.entry, row.amount)
    end
end

local function bind_hearth(player)
    local target = HEARTH_BY_RACE[player:GetRace()]
    if not target then return end
    player:SetBindPoint(target.x, target.y, target.z, target.mapId, target.areaId)
end

local WEAPON_SUBCLASS_SKILL = {
    [ 0] =  44,
    [ 1] = 172,
    [ 2] =  45,
    [ 3] =  46,
    [ 4] =  54,
    [ 5] = 160,
    [ 6] = 229,
    [ 7] =  43,
    [ 8] =  55,
    [10] = 136,
    [13] = 473,
    [15] = 173,
    [16] = 176,
    [18] = 226,
    [19] = 228,
}

local WEAPON_SKILL_PROFICIENCY = {
    [ 43] =   201,
    [ 44] =   196,
    [ 45] =   264,
    [ 46] =   266,
    [ 54] =   198,
    [ 55] =   202,
    [136] =   227,
    [160] =   199,
    [172] =   197,
    [173] =  1180,
    [176] =  2567,
    [226] =  5011,
    [229] =   200,
    [473] = 15590,
}

local CLASS_WEAPON_SKILLS = {
    [ 1] = {  43,  44,  45,  46,  54,  55, 136, 160, 172, 173, 176, 226, 229, 473 },
    [ 2] = {  43,  44,  54,  55, 160, 172, 229 },
    [ 3] = {  43,  44,  45,  46,  55, 136, 172, 173, 176, 226, 229, 473 },
    [ 4] = {  43,  44,  45,  46,  54, 173, 176, 226, 473 },
    [ 5] = {  54, 136, 173, 228 },
    [ 7] = {  44,  54, 136, 160, 172, 173, 473 },
    [ 8] = {  43, 136, 173, 228 },
    [ 9] = {  43, 136, 173, 228 },
    [11] = {  54, 136, 160, 173, 229, 473 },
}

local function train_starter_weapon_skills(player, equipRows)
    local maxForLevel = player:GetLevel() * 5
    for _, row in ipairs(equipRows) do
        if row.class == ITEM_CLASS_WEAPON then
            local skill = WEAPON_SUBCLASS_SKILL[row.subclass]
            if skill and player:HasSkill(skill) then
                player:SetSkill(skill, 0, maxForLevel, maxForLevel)
            end
        end
    end
end

local function learn_weapon_proficiencies(player)
    local skills = CLASS_WEAPON_SKILLS[player:GetClass()]
    if not skills then return end
    for _, skill in ipairs(skills) do
        local spell = WEAPON_SKILL_PROFICIENCY[skill]
        if spell then player:LearnSpell(spell) end
    end
end

local PROFESSION_SKILLS = {
    186, 182, 393, 356, 129, 197, 333,
    164, 165, 171, 202, 755, 773, 185,
}
local function set_profession_skills(player)
    for _, skill in ipairs(PROFESSION_SKILLS) do
        if player:HasSkill(skill) then
            player:SetSkill(skill, 2, 125, 150)
        end
    end
end

local TEMP_ENCHANTMENT_SLOT = 6
local WEAPON_SUBCLASS_ENCHANT = {
    [ 0] =   14,
    [ 1] =   14,
    [ 4] =   21,
    [ 5] =   21,
    [ 6] =   14,
    [ 7] =   14,
    [ 8] =   14,
    [10] = 2623,
    [13] =   14,
    [15] =   14,
    [19] = 2623,
}
local function sharpen_starter_weapon(player)
    local weapon = player:GetEquippedItemBySlot(SLOT_MAINHAND)
    if not weapon then return end
    local enchant = WEAPON_SUBCLASS_ENCHANT[weapon:GetSubClass()]
    if enchant then
        weapon:SetEnchantment(enchant, TEMP_ENCHANTMENT_SLOT)
    end
end

local function apply_kit(playerName, query)
    local player = GetPlayerByName(playerName)
    if not player then return end

    local buckets = categorize_kit(collect_kit_rows(query))

    strip_all_inventory(player)
    learn_weapon_proficiencies(player)
    install_containers(player, buckets.bags)
    install_containers(player, buckets.quiver)
    install_equipment(player, buckets.equip)
    train_starter_weapon_skills(player, buckets.equip)
    set_profession_skills(player)
    sharpen_starter_weapon(player)
    install_ammo(player, buckets.ammo)
    install_hearthstone(player, buckets.hearth)
    bind_hearth(player)
end

local function on_first_login(event, player)
    local race       = player:GetRace()
    local class      = player:GetClass()
    local playerName = player:GetName()

    WorldDBQueryAsync(
        build_kit_query(race, class),
        function(query)
            apply_kit(playerName, query)
        end)
end

RegisterPlayerEvent(PLAYER_EVENT_ON_FIRST_LOGIN, on_first_login)
