-- MARKER_E043_REVERT basic-buddy-selector

DELETE FROM `creature`                WHERE `guid`       BETWEEN 6170001  AND 6170099;
DELETE FROM `creature`                WHERE `guid`       BETWEEN 61700001 AND 61700099;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 6170001  AND 6170003;
DELETE FROM `creature_template`       WHERE `entry`      BETWEEN 6170001  AND 6170003;
DELETE FROM `npc_text`                WHERE `ID`         BETWEEN 6170001  AND 6170003;

