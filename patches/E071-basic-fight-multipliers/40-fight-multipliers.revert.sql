-- MARKER_E071_REVERT basic-fight-multipliers


DELETE FROM `basic_creature_multipliers` WHERE `map_id` = 0 AND `entry` IN (18728);

DELETE FROM `spell_dbc` WHERE `ID` IN (32965, 32964, 59975);
