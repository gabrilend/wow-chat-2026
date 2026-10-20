-- MARKER_E021_REVERT vanilla-starting-professions

DELETE FROM playercreateinfo_skills       WHERE comment LIKE 'vanilla-148q-%';
DELETE FROM playercreateinfo_spell_custom WHERE Note    LIKE 'vanilla-148q-%';
DELETE FROM playercreateinfo_item         WHERE Note    LIKE 'vanilla-148q-%';

