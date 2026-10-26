-- MARKER_E067_REVERT basic-boss-enchant-scrolls

DELETE FROM creature_loot_template WHERE Reference BETWEEN 1558000 AND 1558099;
DELETE FROM reference_loot_template WHERE Entry BETWEEN 1558000 AND 1558099;
