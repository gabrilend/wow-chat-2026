-- MARKER_E021_REVERT vanilla-starting-professions
-- ===========================================================================
-- 07-starting-professions.sql (148q) — REVERT SOURCE
-- ===========================================================================
-- Removes everything the apply form granted: the profession skill lines, the
-- recipe spells, and the tools — all tagged 'vanilla-148q-%'. Nothing else is
-- touched. The first-login hook's skill-value bump is a no-op once the skills
-- are gone (it only bumps professions the character actually HasSkill).
--
-- Database: acore_world_vanilla. Re-applicable: plain scoped DELETEs.
-- ===========================================================================

DELETE FROM playercreateinfo_skills       WHERE comment LIKE 'vanilla-148q-%';
DELETE FROM playercreateinfo_spell_custom WHERE Note    LIKE 'vanilla-148q-%';
DELETE FROM playercreateinfo_item         WHERE Note    LIKE 'vanilla-148q-%';

-- ===========================================================================
-- End of 07-starting-professions.sql (revert)
-- ===========================================================================
