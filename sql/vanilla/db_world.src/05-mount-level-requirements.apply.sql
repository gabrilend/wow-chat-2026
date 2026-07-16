-- MARKER_E020_APPLY vanilla-mount-level-requirements
-- ============================================================================
-- 05-mount-level-requirements.sql (148l) — APPLY SOURCE
-- ============================================================================
-- Push the two ground riding skills to their Classic level gates so that,
-- under vanilla's level-40 cap, the 60%-speed mount becomes the level-cap
-- reward and the 100%-speed mount is a glimpsed-but-unreachable horizon.
--
--   Apprentice Riding (33388): reqlevel 20 -> 40   (reachable only at the cap)
--   Journeyman  Riding (33391): reqlevel 40 -> 60   (needs level 60 — never on
--                                                    a level-40-capped vanilla
--                                                    character; the unreached
--                                                    horizon)
--
-- Modern AzerothCore gates training on `trainer_spell.ReqLevel` (the trainer
-- system, ~12 trainers per riding spell); the legacy `npc_trainer.reqlevel`
-- is updated in lockstep so the two sources never disagree if a rebuild
-- re-derives one from the other. The ticket originally named only
-- npc_trainer, but that table alone does not gate the live trainer handler.
--
-- Database: acore_world_vanilla. Re-applicable: plain UPDATEs, idempotent.
-- Applied by the E020 patch (patches/E-patches.sh) via AC's UpdateFetcher.
-- ============================================================================

UPDATE `trainer_spell` SET `ReqLevel` = 40 WHERE `SpellId` = 33388;
UPDATE `trainer_spell` SET `ReqLevel` = 60 WHERE `SpellId` = 33391;
UPDATE `npc_trainer`   SET `reqlevel` = 40 WHERE `SpellID` = 33388;
UPDATE `npc_trainer`   SET `reqlevel` = 60 WHERE `SpellID` = 33391;

-- ============================================================================
-- End of 05-mount-level-requirements.sql (apply)
-- ============================================================================
