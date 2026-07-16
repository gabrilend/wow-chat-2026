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
local ITEM_CLASS_WEAPON     =  2   -- subclass = weapon type (sword, staff, bow...)
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
    [1]  = { x =  -3827.93, y =   -831.9,  z =  10.09, mapId = 0, areaId =  38 },  -- Human     → Menethil Harbor (Innkeeper Helbrek)
    [2]  = { x =  -1050.04, y =  -3664.8,  z =  23.97, mapId = 1, areaId =  17 },  -- Orc       → Ratchet (Innkeeper Wiley)
    [3]  = { x =  -3827.93, y =   -831.9,  z =  10.09, mapId = 0, areaId =  38 },  -- Dwarf     → Menethil Harbor (Innkeeper Helbrek)
    [4]  = { x =   2781.16, y =   -433.0,  z = 116.67, mapId = 1, areaId = 331 },  -- Night Elf → Astranaar (Innkeeper Kimlya)
    [5]  = { x =     -5.97, y =  -942.28,  z =  57.16, mapId = 0, areaId = 267 },  -- Undead    → Tarren Mill (Innkeeper Shay)
    [6]  = { x =    893.65, y =   927.95,  z = 106.36, mapId = 1, areaId = 406 },  -- Tauren    → Sun Rock Retreat (Innkeeper Jayka)
    [7]  = { x =   2781.16, y =   -433.0,  z = 116.67, mapId = 1, areaId = 331 },  -- Gnome     → Astranaar (Innkeeper Kimlya)
    [8]  = { x =     -5.97, y =  -942.28,  z =  57.16, mapId = 0, areaId = 267 },  -- Troll     → Tarren Mill (Innkeeper Shay)
    [10] = { x =    893.65, y =   927.95,  z = 106.36, mapId = 1, areaId = 406 },  -- Blood Elf → Sun Rock Retreat (Innkeeper Jayka)
    [11] = { x = -10516.0,  y = -1161.21,  z =  28.12, mapId = 0, areaId =  10 },  -- Draenei   → Darkshire (Innkeeper Trelayne)
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
-- {{{ WEAPON_SUBCLASS_SKILL
-- item_template.subclass (when class == ITEM_CLASS_WEAPON) → the weapon
-- skill line that governs it. Used to bring ONLY the starter weapon's
-- skill up to level-appropriate max; every other weapon skill the class
-- knows stays at its default so the player still trains picked-up types
-- the ordinary way (148h "starter weapon only").
local WEAPON_SUBCLASS_SKILL = {
    [ 0] =  44,  -- One-Handed Axe   → Axes
    [ 1] = 172,  -- Two-Handed Axe   → Two-Handed Axes
    [ 2] =  45,  -- Bow              → Bows
    [ 3] =  46,  -- Gun              → Guns
    [ 4] =  54,  -- One-Handed Mace  → Maces
    [ 5] = 160,  -- Two-Handed Mace  → Two-Handed Maces
    [ 6] = 229,  -- Polearm          → Polearms
    [ 7] =  43,  -- One-Handed Sword → Swords
    [ 8] =  55,  -- Two-Handed Sword → Two-Handed Swords
    [10] = 136,  -- Staff            → Staves
    [13] = 473,  -- Fist Weapon      → Fist Weapons
    [15] = 173,  -- Dagger           → Daggers
    [16] = 176,  -- Thrown           → Thrown
    [18] = 226,  -- Crossbow         → Crossbows
    [19] = 228,  -- Wand             → Wands
}
-- }}}

-- {{{ WEAPON_SKILL_PROFICIENCY
-- Weapon skill line → the passive proficiency spell that grants it.
-- LearnSpell of one of these sets the m_WeaponProficiency equip-mask bit
-- AND adds the skill line at default 1 — the ONLY way an off-default kit
-- weapon (a Tauren Warrior's polearm, an Orc Rogue's mace) becomes
-- equippable, since the mask is set by a learned proficiency spell and
-- never by data alone.
--
-- Spell ids verified 2026-07-15 as real weapon-master trainer spells in
-- acore_world.trainer_spell — every id below resolves to a weapon-master
-- listing. Re-check with:
--   SELECT SpellId FROM trainer_spell WHERE SpellId IN
--     (196,197,198,199,200,201,202,227,264,266,1180,2567,5011,15590)
--   GROUP BY SpellId;
--
-- Wands (skill 228) are absent on purpose: the three caster classes carry
-- wand proficiency innately from creation, no weapon master teaches it, so
-- there is nothing to learn — the nil lookup in learn_weapon_proficiencies
-- skips it.
local WEAPON_SKILL_PROFICIENCY = {
    [ 43] =   201,  -- Swords
    [ 44] =   196,  -- Axes
    [ 45] =   264,  -- Bows
    [ 46] =   266,  -- Guns
    [ 54] =   198,  -- Maces
    [ 55] =   202,  -- Two-Handed Swords
    [136] =   227,  -- Staves
    [160] =   199,  -- Two-Handed Maces
    [172] =   197,  -- Two-Handed Axes
    [173] =  1180,  -- Daggers
    [176] =  2567,  -- Thrown
    [226] =  5011,  -- Crossbows
    [229] =   200,  -- Polearms
    [473] = 15590,  -- Fist Weapons
}
-- }}}

-- {{{ CLASS_WEAPON_SKILLS
-- Per-class set of weapon skill lines the class can learn — the weapon
-- skills a class's characters actually hold (148h, derived from live
-- character data, not a from-memory guess). The first-login hook learns a
-- proficiency for every skill here so the player never visits a weapon
-- master and every kit weapon equips. Class ids: 1 War 2 Pal 3 Hun 4 Rog
-- 5 Pri 7 Sha 8 Mag 9 Wlk 11 Dru (6 DK disabled on vanilla per 148a).
--
-- Druids keep Fist (473): correct for WotLK and present in the live data
-- even though the bot factory's CanEquipWeapon omits it. Caster rows keep
-- Wand (228) for fidelity to the source table; it maps to nil above
-- (innate) and is skipped. Dual Wield (spell 674) is NOT here — 148j
-- grants it at creation for the dual-wield kits.
local CLASS_WEAPON_SKILLS = {
    [ 1] = {  43,  44,  45,  46,  54,  55, 136, 160, 172, 173, 176, 226, 229, 473 }, -- Warrior
    [ 2] = {  43,  44,  54,  55, 160, 172, 229 },                                    -- Paladin
    [ 3] = {  43,  44,  45,  46,  55, 136, 172, 173, 176, 226, 229, 473 },           -- Hunter
    [ 4] = {  43,  44,  45,  46,  54, 173, 176, 226, 473 },                          -- Rogue
    [ 5] = {  54, 136, 173, 228 },                                                   -- Priest
    [ 7] = {  44,  54, 136, 160, 172, 173, 473 },                                    -- Shaman
    [ 8] = {  43, 136, 173, 228 },                                                   -- Mage
    [ 9] = {  43, 136, 173, 228 },                                                   -- Warlock
    [11] = {  54, 136, 160, 173, 229, 473 },                                         -- Druid
}
-- }}}

-- {{{ train_starter_weapon_skills
-- Bring the equipped starter weapon(s) up to max-for-level (level*5 =
-- 100 at vanilla's level-20 start), and ONLY those. Other weapon skills
-- stay at their default value so picked-up weapon types still train
-- normally. HasSkill guard: only bump a skill the character actually has
-- — the class-appropriate kit weapon always matches, but the guard keeps
-- us from inventing a proficiency the class shouldn't own. One-shot (this
-- runs inside first-login apply_kit) and NOT a pin: it sets current = max
-- once, then the skill keeps climbing normally as the character passes 20.
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
-- }}}

-- {{{ learn_weapon_proficiencies
-- Learn every weapon proficiency this class can train, run BEFORE the kit
-- is equipped so off-default kit weapons go on and their skill lines exist
-- for train_starter_weapon_skills to sharpen. LearnSpell is idempotent —
-- proficiencies the class already holds from creation are no-ops — so the
-- whole class set is learned without pre-checking. Weapon-skill sibling of
-- 148j's spell pretrain; without it the equip attempts in install_equipment
-- silently fail for any weapon type the class trains rather than starts
-- with, and train_starter_weapon_skills' HasSkill guard then no-ops too.
local function learn_weapon_proficiencies(player)
    local skills = CLASS_WEAPON_SKILLS[player:GetClass()]
    if not skills then return end
    for _, skill in ipairs(skills) do
        local spell = WEAPON_SKILL_PROFICIENCY[skill]
        if spell then player:LearnSpell(spell) end
    end
end
-- }}}

-- {{{ set_profession_skills
-- 148q: the profession migration grants each starting profession at Journeyman
-- (tier 2, cap 150) but only at skill VALUE 1 — playercreateinfo can set the
-- tier, not the value (rank is a tier-step, per 148h's lesson). Bump every
-- profession the character now HAS to 125, the level-20 recipe band, keeping
-- the 150 cap so it still climbs through use. Reads what the character holds,
-- so it needs no per-(race,class) mapping; mirrors the SetSkill idiom in
-- train_starter_weapon_skills. Gathering skills first, then production.
local PROFESSION_SKILLS = {
    186, 182, 393, 356, 129, 197, 333,  -- Mining Herbalism Skinning Fishing FirstAid Tailoring Enchanting
    164, 165, 171, 202, 755, 773, 185,  -- Blacksmithing Leatherworking Alchemy Engineering Jewelcrafting Inscription Cooking
}
local function set_profession_skills(player)
    for _, skill in ipairs(PROFESSION_SKILLS) do
        if player:HasSkill(skill) then
            player:SetSkill(skill, 2, 125, 150)  -- (skill, tier-step, value, max)
        end
    end
end
-- }}}

-- {{{ sharpen_starter_weapon
-- 148u: a one-time "fresh for the road" temporary weapon enhancement on the
-- equipped main-hand, first login only (the hook fires once) — like slapping a
-- stone or oil on before setting out. Tier = the best usable at the level-20
-- start, chosen by item_template.RequiredLevel:
--   Heavy Sharpening Stone (RL 15, spell 2830)  -> temp enchant 14   (blades)
--   Heavy Weightstone      (RL 15, spell 3114)  -> temp enchant 21   (blunt)
--   Minor Wizard Oil       (RL  5, spell 25117) -> temp enchant 2623 (caster)
-- Enchant ids come from the wowhead 3.3.5a spell pages (the DBC enchant tables
-- are empty in this server DB, so they can't be resolved locally) — confirm
-- the exact bonus in-client (148u). Applied to TEMP_ENCHANTMENT_SLOT (6).
-- Ranged main-hands (bow/gun/thrown/crossbow) are left alone.
local TEMP_ENCHANTMENT_SLOT = 6
local WEAPON_SUBCLASS_ENCHANT = {
    [ 0] =   14,  -- One-Handed Axe   → sharpen
    [ 1] =   14,  -- Two-Handed Axe   → sharpen
    [ 4] =   21,  -- One-Handed Mace  → weightstone
    [ 5] =   21,  -- Two-Handed Mace  → weightstone
    [ 6] =   14,  -- Polearm          → sharpen
    [ 7] =   14,  -- One-Handed Sword → sharpen
    [ 8] =   14,  -- Two-Handed Sword → sharpen
    [10] = 2623,  -- Staff            → wizard oil
    [13] =   14,  -- Fist Weapon      → sharpen
    [15] =   14,  -- Dagger           → sharpen
    [19] = 2623,  -- Wand             → wizard oil
}
local function sharpen_starter_weapon(player)
    local weapon = player:GetEquippedItemBySlot(SLOT_MAINHAND)
    if not weapon then return end
    local enchant = WEAPON_SUBCLASS_ENCHANT[weapon:GetSubClass()]
    if enchant then
        weapon:SetEnchantment(enchant, TEMP_ENCHANTMENT_SLOT)
    end
end
-- }}}

local function apply_kit(playerName, query)
    local player = GetPlayerByName(playerName)
    if not player then return end

    local buckets = categorize_kit(collect_kit_rows(query))

    strip_all_inventory(player)
    learn_weapon_proficiencies(player)          -- proficiencies first, so off-default kit weapons can equip (148h)
    install_containers(player, buckets.bags)    -- Linen Bags into 19, 20, 21
    install_containers(player, buckets.quiver)  -- Medium Quiver into 22 (hunters)
    install_equipment(player, buckets.equip)    -- armor, cape, weapons, relic, wand
    train_starter_weapon_skills(player, buckets.equip) -- starter weapon type → max-for-level (148h)
    set_profession_skills(player)               -- professions to skill 125 (148q)
    sharpen_starter_weapon(player)              -- one-time fresh weapon enhancement (148u)
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
