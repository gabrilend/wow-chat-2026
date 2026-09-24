-- MARKER_E012_APPLY beta-drop-creatures-keep-essential
-- drop-creatures-keep-essential.sql
-- Removes all creature spawns except critters and spirit healers
-- Issue 203: drop-all-creatures-except-spirit-healers
-- Issue 201: database-integrity-cleanup (cascade cleanup patterns)
--
-- Critters: creature_template.type = 8 (ambient animals)
-- Spirit Healers: creature_template.npcflag & 16384 (UNIT_NPC_FLAG_SPIRITHEALER)
--
-- Run against acore_world database AFTER fresh import
-- This script is idempotent - safe to run multiple times

-- {{{ snapshot — capture the pre-destruction creature table
-- Apply is destructive: it deletes tens of thousands of spawn rows.
-- To make E012's revert work, we snapshot the full `creature` table
-- BEFORE the destruction into a project-owned table
-- `wow_chat_e012_snapshot_creature`. The unpatch reads from this
-- snapshot to restore the pre-apply state, then drops the snapshot.
--
-- Idempotence:
--   - CREATE TABLE IF NOT EXISTS — second run skips structure creation.
--   - INSERT IGNORE — preserves the original snapshot rows. If apply
--     runs a second time AFTER destruction, the snapshot still has the
--     original rows (depleted creature table can only add NEW guids,
--     not new copies of existing ones — IGNORE catches PK conflicts).
-- Disk cost: ~tens of MB until the unpatch drops the snapshot.
CREATE TABLE IF NOT EXISTS `wow_chat_e012_snapshot_creature` LIKE `creature`;
INSERT IGNORE INTO `wow_chat_e012_snapshot_creature` SELECT * FROM `creature`;
-- }}}

-- {{{ Create temp table of essential creature entries
-- Using regular table because MySQL can't reopen temp tables in subqueries
DROP TABLE IF EXISTS _essential_creatures;
CREATE TABLE _essential_creatures AS
SELECT DISTINCT ct.entry
FROM creature_template ct
WHERE ct.type = 8                         -- Critters (ambient animals)
   OR (ct.npcflag & 16384) = 16384;       -- Spirit Healers (resurrection NPCs)

-- Add index for faster lookups
ALTER TABLE _essential_creatures ADD PRIMARY KEY (entry);
-- }}}

-- {{{ Get GUIDs of creatures to KEEP
DROP TABLE IF EXISTS _keep_guids;
CREATE TABLE _keep_guids AS
SELECT c.guid
FROM creature c
INNER JOIN _essential_creatures ec ON c.id = ec.entry;  -- `id`, not `id1`: renamed upstream in 2026_06_16_00 (fixed 2026-09-23, issue 155c)

ALTER TABLE _keep_guids ADD PRIMARY KEY (guid);
-- }}}

-- {{{ Delete non-essential creature spawns
-- Main creature table - the actual spawns
DELETE c FROM creature c
LEFT JOIN _keep_guids kg ON c.guid = kg.guid
WHERE kg.guid IS NULL;
-- }}}

-- {{{ Clean up related tables (cascade cleanup per issue 201)

-- creature_addon: Extra display/aura data per creature spawn
DELETE ca FROM creature_addon ca
LEFT JOIN _keep_guids kg ON ca.guid = kg.guid
WHERE kg.guid IS NULL;

-- creature_formations: Group movement formations (both leader and member)
DELETE cf FROM creature_formations cf
LEFT JOIN _keep_guids kg ON cf.leaderGUID = kg.guid
WHERE kg.guid IS NULL;

DELETE cf FROM creature_formations cf
LEFT JOIN _keep_guids kg ON cf.memberGUID = kg.guid
WHERE kg.guid IS NULL;

-- linked_respawn: Linked creature respawns
-- linkType 0,1 use guid column; linkType 0,3 use linkedGuid column
DELETE lr FROM linked_respawn lr
LEFT JOIN _keep_guids kg ON lr.guid = kg.guid
WHERE lr.linkType IN (0, 1) AND kg.guid IS NULL;

DELETE lr FROM linked_respawn lr
LEFT JOIN _keep_guids kg ON lr.linkedGuid = kg.guid
WHERE lr.linkType IN (0, 3) AND kg.guid IS NULL;

-- creature_movement_override: Movement overrides per spawn
DELETE cmo FROM creature_movement_override cmo
LEFT JOIN _keep_guids kg ON cmo.SpawnId = kg.guid
WHERE kg.guid IS NULL;

-- game_event_creature: Creatures tied to game events
DELETE gec FROM game_event_creature gec
LEFT JOIN _keep_guids kg ON gec.guid = kg.guid
WHERE kg.guid IS NULL;

-- pool_creature: Creature pooling system
DELETE pc FROM pool_creature pc
LEFT JOIN _keep_guids kg ON pc.guid = kg.guid
WHERE kg.guid IS NULL;

-- conditions: Object entry/guid conditions referencing specific creature GUIDs
-- ConditionTypeOrReference = 31 is CONDITION_OBJECT_ENTRY_GUID
-- ConditionValue1 = 3 means creature type
DELETE cond FROM conditions cond
LEFT JOIN _keep_guids kg ON cond.ConditionValue3 = kg.guid
WHERE cond.ConditionTypeOrReference = 31
  AND cond.ConditionValue1 = 3
  AND kg.guid IS NULL;

-- smart_scripts: GUID-specific script overrides (negative entryorguid with source_type=0)
-- Must run AFTER creature deletion so LEFT JOIN finds orphans
-- entryorguid = -GUID for spawn-specific overrides
DELETE ss FROM smart_scripts ss
LEFT JOIN _keep_guids kg ON ABS(ss.entryorguid) = kg.guid
WHERE ss.source_type = 0
  AND ss.entryorguid < 0
  AND kg.guid IS NULL;

-- }}}

-- {{{ Cleanup temp tables
DROP TABLE IF EXISTS _keep_guids;
DROP TABLE IF EXISTS _essential_creatures;
-- }}}

-- {{{ Verification queries (run manually to check results)
-- SELECT COUNT(*) as remaining_creatures FROM creature;
-- SELECT COUNT(*) as remaining_critters FROM creature c
--   INNER JOIN creature_template ct ON c.id = ct.entry WHERE ct.type = 8;
-- SELECT COUNT(*) as remaining_spirit_healers FROM creature c
--   INNER JOIN creature_template ct ON c.id = ct.entry WHERE (ct.npcflag & 16384) = 16384;
-- }}}
