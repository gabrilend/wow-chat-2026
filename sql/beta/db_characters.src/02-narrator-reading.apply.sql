-- MARKER_E061_APPLY beta-narrator-reading
-- ============================================================================
-- 02-narrator-reading.sql (issue 910a) — APPLY SOURCE
-- ============================================================================
-- Where each narrator is in its book, so it finishes books instead of
-- starting over at every login (the owner, 2026-10-18: "I think we should
-- continue from where we were - it's just an integer in the database, 'how
-- many sentences in'"). Written and read by src/lua-beta/narrators.lua:
-- saved after each sentence, read when the narrator is first heard.
--
--   guid      the narrator bot (characters.guid)
--   book      the book's Gutenberg number (src/lua-beta/data/gutenberg-books.lua)
--   position  how many sentences of it the narrator has read
--
-- Re-applicable: CREATE IF NOT EXISTS keeps the places already saved.
-- Database: acore_characters_beta. Applied by E061.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `beta_910a_narrator_reading` (
  `guid`     int unsigned NOT NULL,
  `book`     int unsigned NOT NULL,
  `position` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 910a: how far each narrator has read';
