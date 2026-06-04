-- MARKER_E016_APPLY beta-empty-loot-chests
-- custom-empty-loot-chests.sql
-- Custom gameobject templates for empty-loot treasure chests
-- Issue 160: custom-empty-loot-chest-templates
-- Issue 167: recreate-missing-sql-files
--
-- These are visual clones of vanilla chests with data1=0 (no loot template)
-- All loot comes from Lua injection via chest:AddLoot()
-- Holder sees truly EMPTY chest; Searcher triggers loot injection
--
-- Entry IDs: 900001-900037 (custom namespace)
-- Run against acore_world database

-- {{{ Clean up existing entries if they exist
DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 900001 AND 900037;
-- }}}

-- {{{ Create custom chest entries by copying from vanilla and setting data1=0
-- Structure: entry, type, displayId, name, IconName, castBarCaption, unk1, size, data0-data23, AIName, ScriptName
-- For type=3 (GAMEOBJECT_TYPE_CHEST):
--   data0 = lockId (keep same for lockpicking/key requirements)
--   data1 = lootId (SET TO 0 - no built-in loot)
--   data2 = chestRestockTime (0 = no restock)
--   data3 = consumable (1 = despawn after loot)
--   data4 = minRestock
--   data5 = maxRestock
--   data6 = lootedEvent (0 = none)
--   data7 = linkedTrap
--   data8 = questId
--   data9 = level
--   data10 = losOK
--   data11 = leaveLoot (0 = remove on despawn)
--   data12 = notInCombat
--   data13 = logLoot
--   data14 = openTextId
--   data15 = useGroupLootRules
--   data16 = floatingTooltip

-- 900001 - Battered Chest (vanilla 2843)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900001, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 2843;

-- 900002 - Tattered Chest (vanilla 106318)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900002, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 106318;

-- 900003 - Solid Chest (vanilla 106319)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900003, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 106319;

-- 900004 - Large Iron Bound Chest (vanilla 75293)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900004, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 75293;

-- 900005 - Large Solid Chest (vanilla 75298)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900005, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 75298;

-- 900006 - Large Mithril Bound Chest (vanilla 74448)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900006, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 74448;

-- 900007 - Large Darkwood Chest (vanilla 75299)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900007, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 75299;

-- 900008 - Large Battered Chest (vanilla 75300)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900008, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 75300;

-- 900009 - Captain's Chest (vanilla 142184)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900009, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 142184;

-- 900010 - Uldaman Chest (vanilla 141979)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900010, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 141979;

-- 900011 - Arena Chest (vanilla 179697)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900011, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 179697;

-- 900012 - Vendor Trash Chest (vanilla 190552)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900012, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 190552;

-- 900013 - Felwood Chest (vanilla 153464)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900013, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 153464;

-- 900014 - Dire Maul Chest (vanilla 179564)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900014, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 179564;

-- 900015 - Silithus Chest (vanilla 179528)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900015, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 179528;

-- 900016 - Outland Chest 1 (vanilla 181804)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900016, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 181804;

-- 900017 - Ramparts Chest (vanilla 185168)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900017, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 185168;

-- 900018 - Outland Chest 2 (vanilla 184930)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900018, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 184930;

-- 900019 - Outland Chest 3 (vanilla 184933)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900019, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 184933;

-- 900020 - Outland Chest 4 (vanilla 184937)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900020, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 184937;

-- 900021 - Outland Chest 5 (vanilla 184941)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900021, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 184941;

-- 900022 - TBC Green Chest (vanilla 186744)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900022, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 186744;

-- 900023 - Mechanar Chest (vanilla 184465)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900023, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 184465;

-- 900024 - Zul'Aman Chest (vanilla 186672)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900024, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 186672;

-- 900025 - TBC Cloaks Chest (vanilla 187892)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900025, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 187892;

-- 900026 - TBC Amulets Chest (vanilla 188191)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900026, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 188191;

-- 900027 - HoS Normal Chest (vanilla 190586)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900027, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 190586;

-- 900028 - HoS Heroic Chest (vanilla 193996)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900028, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 193996;

-- 900029 - CoS Chest (vanilla 190663)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900029, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 190663;

-- 900030 - Rusted Footlocker (vanilla 193402)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900030, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 193402;

-- 900031 - Oculus Chest (vanilla 193603)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900031, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 193603;

-- 900032 - Eye of Eternity Chest (vanilla 193905)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900032, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 193905;

-- 900033 - Ulduar Chest 1 (vanilla 194331)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900033, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 194331;

-- 900034 - Cache of Winter (vanilla 194308)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900034, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 194308;

-- 900035 - Rare Cache (vanilla 194201)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900035, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 194201;

-- 900036 - Four Horsemen Chest (vanilla 181366)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900036, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 181366;

-- 900037 - Dinosaur Bone Chest (vanilla 2849)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
SELECT 900037, `type`, `displayId`, 'Treasure Chest', `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, 0, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
FROM `gameobject_template` WHERE `entry` = 2849;
-- }}}

-- {{{ Custom Chest ID Mapping Reference (for Lua code)
-- 900001 = Battered Chest (vanilla 2843) - Level 1-5
-- 900002 = Tattered Chest (vanilla 106318) - Level 3-7
-- 900003 = Solid Chest (vanilla 106319) - Level 6-10
-- 900004 = Large Iron Bound (vanilla 75293) - Level 11-15
-- 900005 = Large Solid (vanilla 75298) - Level 16-21
-- 900006 = Large Mithril (vanilla 74448) - Level 21-27
-- 900007 = Large Darkwood (vanilla 75299) - Level 27-31
-- 900008 = Large Battered (vanilla 75300) - Level 30-35
-- 900009 = Captain's Chest (vanilla 142184) - Level 36-41
-- 900010 = Uldaman (vanilla 141979) - Level 36-40
-- 900011 = Arena (vanilla 179697) - Level 41-49
-- 900012 = Vendor Trash (vanilla 190552) - Level 40-80
-- 900013 = Felwood (vanilla 153464) - Level 50-60
-- 900014 = Dire Maul (vanilla 179564) - Level 54-59
-- 900015 = Silithus (vanilla 179528) - Level 55-80
-- 900016 = Outland 1 (vanilla 181804) - Level 57-62
-- 900017 = Ramparts (vanilla 185168) - Level 60
-- 900018 = Outland 2 (vanilla 184930) - Level 60-64
-- 900019 = Outland 3 (vanilla 184933) - Level 64-66
-- 900020 = Outland 4 (vanilla 184937) - Level 66-68
-- 900021 = Outland 5 (vanilla 184941) - Level 68-74
-- 900022 = TBC Green (vanilla 186744) - Level 69-72
-- 900023 = Mechanar (vanilla 184465) - Level 69-71
-- 900024 = Zul'Aman (vanilla 186672) - Level 72-79
-- 900025 = TBC Cloaks (vanilla 187892) - Level 72-79
-- 900026 = TBC Amulets (vanilla 188191) - Level 72-79
-- 900027 = HoS Normal (vanilla 190586) - Level 76-79
-- 900028 = HoS Heroic (vanilla 193996) - Level 80
-- 900029 = CoS (vanilla 190663) - Level 78-80
-- 900030 = Rusted Footlocker (vanilla 193402) - Level 80
-- 900031 = Oculus (vanilla 193603) - Level 80
-- 900032 = Eye of Eternity (vanilla 193905) - Level 80
-- 900033 = Ulduar 1 (vanilla 194331) - Level 80
-- 900034 = Cache of Winter (vanilla 194308) - Level 80
-- 900035 = Rare Cache (vanilla 194201) - Level 80
-- 900036 = Four Horsemen (vanilla 181366) - Level 80
-- 900037 = Dinosaur Bone (vanilla 2849) - Level 1-80
-- }}}

-- {{{ Verification query (run manually)
-- SELECT entry, name, Data1 FROM gameobject_template WHERE entry BETWEEN 900001 AND 900037;
-- Expected: All entries should have Data1 = 0
-- }}}
