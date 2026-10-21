-- MARKER_E019_APPLY vanilla-no-intro-cinematic
-- Carried by its install step (issue 189e), which every profile taking it
-- applies to its own databases (basic and vanilla, its header says). Edits
-- land on both; if one ever needs different content, it gets a patch of its
-- own, since profiles never read each other's folders.
-- Apply-form: BEFORE INSERT trigger on the characters table that
-- sets cinematic = 1 for every newly created character. The
-- cinematic column tracks "has the race intro played yet?"; AC's
-- worldserver checks this on first login and plays the appropriate
-- race intro if it's still 0. Pre-setting to 1 short-circuits that
-- check — first login skips straight to gameplay.
--
-- Vanilla-scoped (acore_characters_vanilla). Release/beta read a
-- different characters DB so their race intros stay on for users
-- who want them. The trigger requires log_bin_trust_function_creators
-- = 1 in my.cnf so ritz can install it without SUPER privilege —
-- the project-local MySQL is configured for that.
DROP TRIGGER IF EXISTS `tr_no_intro_cinematic`;
CREATE TRIGGER `tr_no_intro_cinematic` BEFORE INSERT ON `characters` FOR EACH ROW SET NEW.cinematic = 1;
