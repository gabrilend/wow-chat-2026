-- MARKER_E023_REVERT basic-starting-valley-rotation
-- Revert-form (issue 155d): drop the rotation state. Characters already
-- placed keep their positions and home points; only future creations are
-- affected, and with B028 also reverted they use their race's own valley.
DROP TABLE IF EXISTS `basic_starting_valley_rotation`;
