--------------------------------------------------------------------------------
-- auto-equip-starter-kit.lua (148k)
--
-- ALE hook fired once per character on first login. The shape is:
--   1. Async-query the world DB for this (race, class)'s kit from
--      playercreateinfo_item joined against item_template, so the kit
--      definition has exactly one source of truth (the S4 SQL).
--   2. In the callback, strip every item the player owns — no allow-
--      listing, no checking, just empty the equipped slots, the equipped
--      bag positions, and the main backpack.
--   3. AddItem + Equip the kit in a deliberate order:
--        a. Linen Bags into bag-positions 19-21.
--        b. Medium Quiver into bag-position 22 (hunters only) — LAST,
--           so it's the only ammo container at step (d).
--        c. Armor, cape, weapons, relic, wand — routed by InventoryType.
--        d. Ammo — AddItem after the quiver exists, so the engine routes
--           the new stack into the quiver instead of the backpack.
--        e. Hearthstone — AddItem to the backpack.
--   4. SetBindPoint to this character's race's anchor town (148n's
--      per-race spread — Wetlands/Ashenvale/Hillsbrad/Stonetalon/Ratchet/
--      Duskwood), so the freshly-granted hearthstone teleports back to
--      the right town instead of a one-size-fits-faction default.
--
-- Design pillars (user 2026-06-02):
--   "A character should have nothing but the things we provide, and maybe
--    a hearthstone set to duskwood / hillsbrad."
--   "We should remove ALL items. That way we don't even have to check.
--    Just strip them all, then re-add the ones we want."
--   "Make sure we equip bags first, then quiver last."
--   "Why not just wait to add the ammo until the quiver is equipped?"
--   "The quiver can only hold ammunition... treat quivers as extra bonus
--    slots just for hunters."
--
-- See issues/148k-ale-auto-equip-starter-kit.md for the long-form spec.
-- The kit data itself lives in scripts/generate-vanilla-starting-equipment-sql.
--------------------------------------------------------------------------------

-- {{{ event_constant
local PLAYER_EVENT_ON_FIRST_LOGIN = 30
-- }}}

-- {{{ inventory_layout
local BAG_ALL              = 255
local EQUIPPED_SLOT_START  =  0
local EQUIPPED_SLOT_END    = 18
local BAG_SLOT_START       = 19
local BAG_SLOT_END         = 22
local BACKPACK_SLOT_START  = 23
local BACKPACK_SLOT_END    = 38
-- }}}

-- {{{ equipment_slots
-- 3.3.5a equipment-slot enumeration from docs/ale/docs/Player/EquipItem.html.
local SLOT_HEAD       =  0
local SLOT_NECK       =  1
local SLOT_SHOULDERS  =  2
local SLOT_BODY       =  3  -- shirt
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
-- }}}

-- {{{ inventory_type_routing
-- item_template.InventoryType → equipment slot for routing equippable
-- items. Bag containers and ammo bypass this table; see categorize().
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
-- }}}

-- {{{ item_category_constants
-- The kit JOIN gives us item_template.class + subclass for each row, so
-- the routing logic dispatches on those rather than on hardcoded entry
-- IDs. New bag, quiver, or ammo entries added later route correctly.
local ITEM_CLASS_CONTAINER  =  1   -- subclass 0 = bag (Linen Bag, etc.)
local ITEM_CLASS_PROJECTILE =  6   -- arrows, bullets (subclass distinguishes)
local ITEM_CLASS_QUIVER     = 11   -- subclass 2 = quiver, 3 = ammo pouch
local HEARTHSTONE_ENTRY     = 6948
-- }}}

-- {{{ hearthstone_targets
-- 148n: per-race spawn anchors that mirror E007's per-race
-- playercreateinfo UPDATEs. Each row is the town where this race
-- materialises at level 20, and where its hearthstone should drop
-- the character back when cast. Map 0 = Eastern Kingdoms, map 1 =
-- Kalimdor; areaId is the AC zone id.
--
-- Race 9 (Goblin slot, reserved pre-Cataclysm) is absent. DK
-- characters (class=6) are disabled on vanilla per 148a; if a DK
-- ever returns, this table would need a class branch sending them
-- to Ebon Hold instead.
local HEARTH_BY_RACE = {
    [1]  = { x =  -3826.0,    y =   -793.0,    z =  19.0,    mapId = 0, areaId =  38 },  -- Human     → Wetlands / Menethil Harbor
    [2]  = { x =   -978.0,    y =  -3771.0,    z =   5.0,    mapId = 1, areaId =  17 },  -- Orc       → N. Barrens / Ratchet
    [3]  = { x =  -3826.0,    y =   -793.0,    z =  19.0,    mapId = 0, areaId =  38 },  -- Dwarf     → Wetlands / Menethil Harbor
    [4]  = { x =   2728.0,    y =   -380.0,    z = 107.0,    mapId = 1, areaId = 331 },  -- Night Elf → Ashenvale / Astranaar
    [5]  = { x =    -34.1467, y =   -923.366,  z =  54.5576, mapId = 0, areaId = 267 },  -- Undead    → Hillsbrad / Tarren Mill
    [6]  = { x =    736.0,    y =   1019.0,    z = 137.0,    mapId = 1, areaId = 406 },  -- Tauren    → Stonetalon / Sun Rock Retreat
    [7]  = { x =   2728.0,    y =   -380.0,    z = 107.0,    mapId = 1, areaId = 331 },  -- Gnome     → Ashenvale / Astranaar
    [8]  = { x =    -34.1467, y =   -923.366,  z =  54.5576, mapId = 0, areaId = 267 },  -- Troll     → Hillsbrad / Tarren Mill
    [10] = { x =    736.0,    y =   1019.0,    z = 137.0,    mapId = 1, areaId = 406 },  -- Blood Elf → Stonetalon / Sun Rock Retreat
    [11] = { x = -10573.0,    y =  -1182.51,   z =  28.0148, mapId = 0, areaId =  10 },  -- Draenei   → Duskwood / Darkshire
}
-- }}}

-- {{{ build_kit_query
-- The SQL pulls every row this character will own at first login:
-- the kit items themselves plus their InventoryType/class/subclass
-- metadata. The DB lookup is the source of truth — the Lua does not
-- duplicate the kit definition.
--
-- The Note-prefix filter scopes the result to S4's rows (the Note tag
-- 'vanilla-148h-*' that the bash generator stamps on every INSERT).
-- Existing AC-default rows for this (race, class) tagged with NULL
-- Notes — the level-1 starter shirt, etc. — are deliberately excluded.
local function build_kit_query(race, class)
    return string.format([[
        SELECT pci.itemid, pci.amount, it.InventoryType, it.class, it.subclass
        FROM playercreateinfo_item pci
        JOIN item_template it ON it.entry = pci.itemid
        WHERE pci.race = %d AND pci.class = %d
          AND pci.Note LIKE 'vanilla-148h-%%'
        ORDER BY pci.itemid]], race, class)
end
-- }}}

-- {{{ collect_kit_rows
-- Drain an ALEQuery result into a list of plain tables. Defensive
-- check on query: WorldDBQueryAsync passes nil for empty result sets.
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
-- }}}

-- {{{ categorize_kit
-- Sort kit rows into the buckets that drive install order:
--   bags     — Linen Bags, equipped to slots 19-21 first.
--   quiver   — Medium Quiver, equipped to slot 22 LAST among containers,
--              so it's the only ammo destination when ammo is added.
--   ammo     — Sharp Arrow, AddItem'd after quiver so it lands in quiver.
--   hearth   — Hearthstone, AddItem'd to backpack as the final tangible.
--   equip    — everything else: armor, cape, weapons, relic, wand.
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
-- }}}

-- {{{ strip_all_inventory
-- Empty every slot the character owns. No allowlist, no per-entry
-- check — the kit will be re-added from the DB query immediately
-- after, so what's stripped now doesn't matter.
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
-- }}}

-- {{{ first_empty_bag_slot
-- Walk bag positions 19-22 for the first empty one. Returns slot index
-- or nil if all four are full. Used to place bags and the quiver in
-- left-to-right order.
local function first_empty_bag_slot(player)
    for slot = BAG_SLOT_START, BAG_SLOT_END do
        if player:GetItemByPos(BAG_ALL, slot) == nil then
            return slot
        end
    end
    return nil
end
-- }}}

-- {{{ install_containers
-- AddItem each bag/quiver row's stack as individual containers, then
-- equip each one to the next empty bag-position. Bags install first
-- (slots 19-21), then the quiver (slot 22 for hunters), so ammo added
-- next has the quiver as its natural destination.
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
-- }}}

-- {{{ install_equipment
-- AddItem + equip everything in the kit that maps to an equipment slot.
-- Two passes handle the dual-wield case (orc hunter dual axes; default
-- rogue dual Kris; BE/NE rogue dual swords; Undead/Orc rogue 1H + dagger
-- where the second is also 1H). Pass 1 equips the first copy to MAINHAND;
-- pass 2 finds the second copy in the backpack with MAINHAND occupied
-- and routes it to OFFHAND.
local function install_equipment(player, rows)
    -- Pass 1: AddItem every row, attempt main equip
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
-- }}}

-- {{{ install_ammo
-- AddItem ammo rows after the quiver is equipped. With the quiver as
-- the player's only ammo-capable container, the engine routes the new
-- arrow stack into the quiver instead of the backpack — no Remove/
-- re-Add gymnastics required.
local function install_ammo(player, rows)
    for _, row in ipairs(rows) do
        player:AddItem(row.entry, row.amount)
    end
end
-- }}}

-- {{{ install_hearthstone
-- AddItem the hearthstone last. It lands in whichever bag has room
-- (typically the first equipped Linen Bag). The bind point gets set
-- afterward in bind_hearth.
local function install_hearthstone(player, rows)
    for _, row in ipairs(rows) do
        player:AddItem(row.entry, row.amount)
    end
end
-- }}}

-- {{{ bind_hearth
-- SetBindPoint to this character's race's anchor town. Unknown race
-- (e.g. race 9 = pre-Cataclysm Goblin reserved slot, or a future
-- race we haven't tabled yet) returns without binding — the
-- character keeps whatever default hearth the engine assigned at
-- creation. Not a silent failure: an explicit nil-table-lookup
-- means "we don't have an opinion for this race," not "binding
-- broke."
local function bind_hearth(player)
    local target = HEARTH_BY_RACE[player:GetRace()]
    if not target then return end
    player:SetBindPoint(target.x, target.y, target.z, target.mapId, target.areaId)
end
-- }}}

-- {{{ apply_kit
-- Callback for the async kit query. Re-resolves the player by name —
-- the async window between query dispatch and callback completion is
-- the player's first-login moment, but defensive coding pays for
-- itself the one time the player disconnects mid-fetch.
local function apply_kit(playerName, query)
    local player = GetPlayerByName(playerName)
    if not player then return end

    local buckets = categorize_kit(collect_kit_rows(query))

    strip_all_inventory(player)
    install_containers(player, buckets.bags)    -- Linen Bags into 19, 20, 21
    install_containers(player, buckets.quiver)  -- Medium Quiver into 22 (hunters)
    install_equipment(player, buckets.equip)    -- armor, cape, weapons, relic, wand
    install_ammo(player, buckets.ammo)          -- Sharp Arrow → routes into quiver
    install_hearthstone(player, buckets.hearth) -- Hearthstone → first available bag
    bind_hearth(player)                         -- bind to race's anchor town (148n)
end
-- }}}

-- {{{ on_first_login
-- Dispatch the async kit fetch and bounce into apply_kit when results
-- come back. The async pattern follows ambush.lua's precedent and
-- avoids the buffer-corruption bug noted in ALE's sync WorldDBQuery.
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
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_FIRST_LOGIN, on_first_login)
