-- MARKER_E019_APPLY vanilla-no-intro-cinematic
DROP TRIGGER IF EXISTS `tr_no_intro_cinematic`;
CREATE TRIGGER `tr_no_intro_cinematic` BEFORE INSERT ON `characters` FOR EACH ROW SET NEW.cinematic = 1;
