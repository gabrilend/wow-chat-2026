-- MARKER_E020_REVERT vanilla-mount-level-requirements
-- SHARED: sql/basic/ links to this file (issue 155c) — the basic profile
-- applies the same content to its own databases. Edits here land on both
-- vanilla and basic; if basic ever needs different content, replace its
-- link with a real file.
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
-- (2026-09-23) The two `npc_trainer` UPDATEs that used to follow are gone:
-- upstream update 2025_12_29_12 dropped the legacy npc_trainer table (trainer
-- data lives only in trainer / trainer_spell now), so those statements would
-- stop the database update with "table doesn't exist".

-- ============================================================================
-- End of 05-mount-level-requirements.sql (revert)
-- ============================================================================
