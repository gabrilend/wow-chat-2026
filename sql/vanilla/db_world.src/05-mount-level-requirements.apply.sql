-- MARKER_E020_APPLY vanilla-mount-level-requirements
-- SHARED: the basic profile (issue 155c) reads this file too (E-patches.sh,
-- _shared_sql_src) and applies it to its own databases. Edits land on both
-- vanilla and basic; if basic ever needs different content, give it its
-- own file under sql/basic/ and drop it from the sharing table.
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
-- system, ~12 trainers per riding spell). An earlier version also updated the
-- legacy `npc_trainer` table in lockstep; upstream has since dropped that
-- table (see the note below the UPDATEs).
--
-- Database: acore_world_vanilla. Re-applicable: plain UPDATEs, idempotent.
-- Applied by the E020 patch (patches/E-patches.sh) via AC's UpdateFetcher.
-- ============================================================================

UPDATE `trainer_spell` SET `ReqLevel` = 40 WHERE `SpellId` = 33388;
UPDATE `trainer_spell` SET `ReqLevel` = 60 WHERE `SpellId` = 33391;
-- (2026-09-23) The two `npc_trainer` UPDATEs that used to follow are gone:
-- upstream update 2025_12_29_12 dropped the legacy npc_trainer table (trainer
-- data lives only in trainer / trainer_spell now), so those statements would
-- stop the database update with "table doesn't exist".

-- ============================================================================
-- End of 05-mount-level-requirements.sql (apply)
-- ============================================================================
