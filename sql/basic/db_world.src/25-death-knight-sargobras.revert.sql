-- MARKER_E040_REVERT basic-death-knight-sargobras

DELETE FROM `creature`                WHERE `guid`       BETWEEN 7180001 AND 7180002;
DELETE FROM `creature`                WHERE `guid`       = 71800001;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 7180001 AND 7180002;
DELETE FROM `creature_template`       WHERE `entry`      BETWEEN 7180001 AND 7180002;
DELETE FROM `npc_text`                WHERE `ID` BETWEEN 7180001 AND 7180003;

