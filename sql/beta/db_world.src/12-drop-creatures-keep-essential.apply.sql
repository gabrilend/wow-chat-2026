-- MARKER_E012_APPLY beta-drop-creatures-keep-essential

CREATE TABLE IF NOT EXISTS `wow_chat_e012_snapshot_creature` LIKE `creature`;
INSERT IGNORE INTO `wow_chat_e012_snapshot_creature` SELECT * FROM `creature`;

DROP TABLE IF EXISTS _essential_creatures;
CREATE TABLE _essential_creatures AS
SELECT DISTINCT ct.entry
FROM creature_template ct
WHERE ct.type = 8                         -- Critters (ambient animals)
   OR (ct.npcflag & 16384) = 16384;       -- Spirit Healers (resurrection NPCs)

ALTER TABLE _essential_creatures ADD PRIMARY KEY (entry);

DROP TABLE IF EXISTS _keep_guids;
CREATE TABLE _keep_guids AS
SELECT c.guid
FROM creature c
INNER JOIN _essential_creatures ec ON c.id = ec.entry;  -- `id`, not `id1`: renamed upstream in 2026_06_16_00 (fixed 2026-09-23, issue 155c)

ALTER TABLE _keep_guids ADD PRIMARY KEY (guid);

DELETE c FROM creature c
LEFT JOIN _keep_guids kg ON c.guid = kg.guid
WHERE kg.guid IS NULL;


DELETE ca FROM creature_addon ca
LEFT JOIN _keep_guids kg ON ca.guid = kg.guid
WHERE kg.guid IS NULL;

DELETE cf FROM creature_formations cf
LEFT JOIN _keep_guids kg ON cf.leaderGUID = kg.guid
WHERE kg.guid IS NULL;

DELETE cf FROM creature_formations cf
LEFT JOIN _keep_guids kg ON cf.memberGUID = kg.guid
WHERE kg.guid IS NULL;

DELETE lr FROM linked_respawn lr
LEFT JOIN _keep_guids kg ON lr.guid = kg.guid
WHERE lr.linkType IN (0, 1) AND kg.guid IS NULL;

DELETE lr FROM linked_respawn lr
LEFT JOIN _keep_guids kg ON lr.linkedGuid = kg.guid
WHERE lr.linkType IN (0, 3) AND kg.guid IS NULL;

DELETE cmo FROM creature_movement_override cmo
LEFT JOIN _keep_guids kg ON cmo.SpawnId = kg.guid
WHERE kg.guid IS NULL;

DELETE gec FROM game_event_creature gec
LEFT JOIN _keep_guids kg ON gec.guid = kg.guid
WHERE kg.guid IS NULL;

DELETE pc FROM pool_creature pc
LEFT JOIN _keep_guids kg ON pc.guid = kg.guid
WHERE kg.guid IS NULL;

DELETE cond FROM conditions cond
LEFT JOIN _keep_guids kg ON cond.ConditionValue3 = kg.guid
WHERE cond.ConditionTypeOrReference = 31
  AND cond.ConditionValue1 = 3
  AND kg.guid IS NULL;

DELETE ss FROM smart_scripts ss
LEFT JOIN _keep_guids kg ON ABS(ss.entryorguid) = kg.guid
WHERE ss.source_type = 0
  AND ss.entryorguid < 0
  AND kg.guid IS NULL;


DROP TABLE IF EXISTS _keep_guids;
DROP TABLE IF EXISTS _essential_creatures;

