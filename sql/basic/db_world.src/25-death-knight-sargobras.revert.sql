-- MARKER_E040_REVERT basic-death-knight-sargobras
-- ============================================================================
-- 25-death-knight-sargobras.sql (issue 718) — REVERT SOURCE
-- ============================================================================
-- Sargobras, his texts and his spawn in the Ebon Hold, removed.
-- ============================================================================

DELETE FROM `creature`                WHERE `guid`       = 71800001;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 7180001;
DELETE FROM `creature_template`       WHERE `entry`      = 7180001;
DELETE FROM `npc_text`                WHERE `ID` BETWEEN 7180001 AND 7180003;

-- ============================================================================
-- End of 25-death-knight-sargobras.sql (revert)
-- ============================================================================
