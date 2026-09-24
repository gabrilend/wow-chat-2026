-- MARKER_E019_APPLY vanilla-no-intro-cinematic
-- SHARED: the basic profile (issue 155c) reads this file too (E-patches.sh,
-- _shared_sql_src) and applies it to its own databases. Edits land on both
-- vanilla and basic; if basic ever needs different content, give it its
-- own file under sql/basic/ and drop it from the sharing table.
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
