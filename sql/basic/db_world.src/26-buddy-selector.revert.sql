-- MARKER_E043_REVERT basic-buddy-selector
-- ============================================================================
-- 26-buddy-selector.sql (issue 617b) — REVERT SOURCE
-- ============================================================================
-- Removes both Sargobras creatures, the valley spawns and the texts. Nothing
-- else was changed. A wandering Sargobras is only ever summoned by the Lua
-- script and never saved, so there is nothing of his to remove here.
-- ============================================================================

DELETE FROM `creature`                WHERE `guid`       BETWEEN 61700001 AND 61700099;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 6170001  AND 6170002;
DELETE FROM `creature_template`       WHERE `entry`      BETWEEN 6170001  AND 6170002;
DELETE FROM `npc_text`                WHERE `ID`         BETWEEN 6170001  AND 6170003;

-- ============================================================================
-- End of 26-buddy-selector.sql (revert)
-- ============================================================================
