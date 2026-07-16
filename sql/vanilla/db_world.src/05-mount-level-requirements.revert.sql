-- MARKER_E020_REVERT vanilla-mount-level-requirements
-- ============================================================================
-- 05-mount-level-requirements.sql (148l) — REVERT SOURCE
-- ============================================================================
-- Restore AzerothCore's WotLK defaults: Apprentice Riding trainable at level
-- 20, Journeyman at 40 — across both the modern `trainer_spell` gate and the
-- legacy `npc_trainer` table, matching what the apply form touched.
--
-- Database: acore_world_vanilla. Re-applicable: plain UPDATEs, idempotent.
-- ============================================================================

UPDATE `trainer_spell` SET `ReqLevel` = 20 WHERE `SpellId` = 33388;
UPDATE `trainer_spell` SET `ReqLevel` = 40 WHERE `SpellId` = 33391;
UPDATE `npc_trainer`   SET `reqlevel` = 20 WHERE `SpellID` = 33388;
UPDATE `npc_trainer`   SET `reqlevel` = 40 WHERE `SpellID` = 33391;

-- ============================================================================
-- End of 05-mount-level-requirements.sql (revert)
-- ============================================================================
