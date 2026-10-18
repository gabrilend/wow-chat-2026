--------------------------------------------------------------------------------
-- gutenberg-books.lua (issue 909) - the narrators' bookshelf
--
-- For a general audience: the books the narrators read aloud, chosen by
-- hand for a fantasy world (fairy tales, fables, myths, adventures, old
-- philosophy), each named by its Project Gutenberg number. The scraper
-- (scripts/gutenberg-scraper) downloads each one and checks that the
-- title in the downloaded file contains `match` before keeping it: a
-- mistyped number fetches a different book entirely, and that must stop
-- the book rather than slip onto the shelf.
--
-- Each entry: id (integer, the Gutenberg number), slug (text, the folder
-- name under data/texts/ after "<id>-"), title and author (text, for
-- people), genre (text), match (text, lower case, must be found in the
-- downloaded file's lower-cased "Title:" line), starts (text: the first
-- words of the story itself, as cut into sentences; every sentence
-- before the first that starts with them is left out, which drops
-- prefaces, translators' notes, publishers and tables of contents. Words
-- the scraper can't find stop the book rather than keep it whole), ends
-- (text, where needed: the first words of what follows the story, notes,
-- glossaries, indexes, afterwords; left out from there on, and words the
-- scraper can't find stop the book), and
-- verse_line_numbers (true, only where the text numbers every fifth line
-- of verse: those numbers are taken out).
--
-- ALE loads every .lua in the beta tree; this one only returns a table.
--------------------------------------------------------------------------------

return {
    { id =    11, slug = "alice-in-wonderland",     title = "Alice's Adventures in Wonderland", author = "Lewis Carroll",        genre = "fantasy",    match = "alice", starts = "Alice was beginning to get very tired" },
    { id =    12, slug = "through-the-looking-glass", title = "Through the Looking-Glass",      author = "Lewis Carroll",        genre = "fantasy",    match = "looking-glass", starts = "One thing was certain" },
    { id =    16, slug = "peter-pan",               title = "Peter Pan",                        author = "J. M. Barrie",         genre = "fantasy",    match = "peter pan", starts = "All children, except one, grow up" },
    { id =    21, slug = "aesops-fables",           title = "Aesop's Fables",                   author = "Aesop",                genre = "fable",      match = "aesop", starts = "WOLF, meeting with a Lamb", ends = "1 (return)" },   -- the fable's "A" stands alone as a drop capital, and is lost
    { id =    55, slug = "wizard-of-oz",            title = "The Wonderful Wizard of Oz",       author = "L. Frank Baum",        genre = "fantasy",    match = "wizard of oz", starts = "Dorothy lived in the midst of the great Kansas prairies" },
    { id =   120, slug = "treasure-island",         title = "Treasure Island",                  author = "Robert Louis Stevenson", genre = "adventure", match = "treasure island", starts = "Squire Trelawney, Dr. Livesey" },
    { id =   236, slug = "jungle-book",             title = "The Jungle Book",                  author = "Rudyard Kipling",      genre = "adventure",  match = "jungle book", starts = "It was seven o'clock of a very warm evening" },
    { id =   289, slug = "wind-in-the-willows",     title = "The Wind in the Willows",          author = "Kenneth Grahame",      genre = "fantasy",    match = "wind in the willows", starts = "The Mole had been working very hard" },
    { id =   521, slug = "robinson-crusoe",         title = "Robinson Crusoe",                  author = "Daniel Defoe",         genre = "adventure",  match = "robinson crusoe", starts = "I was born in the year 1632" },
    { id =   829, slug = "gullivers-travels",       title = "Gulliver's Travels",               author = "Jonathan Swift",       genre = "adventure",  match = "gulliver", starts = "My father had a small estate in Nottinghamshire" },
    { id =  1597, slug = "andersens-fairy-tales",   title = "Andersen's Fairy Tales",           author = "Hans Christian Andersen", genre = "fairy tale", match = "andersen", starts = "Many years ago, there was an Emperor" },
    { id =  2591, slug = "grimms-fairy-tales",      title = "Grimms' Fairy Tales",              author = "Jacob and Wilhelm Grimm", genre = "fairy tale", match = "grimm", starts = "A certain king had a beautiful garden", ends = "The Brothers Grimm, Jacob" },
    { id =  2680, slug = "meditations",             title = "Meditations",                      author = "Marcus Aurelius",      genre = "philosophy", match = "meditations", starts = "Of my grandfather Verus", ends = "M. CORNELIUS FRONTO" },
    { id =  1727, slug = "odyssey",                 title = "The Odyssey",                      author = "Homer",                genre = "myth",       match = "odyssey", starts = "Tell me, O Muse", ends = "29[] [ The geography" },   -- the notes follow the story; their first is numbered "29[]" in the source as given
    { id = 16328, slug = "beowulf",                 title = "Beowulf",                          author = "anonymous",            genre = "epic",       match = "beowulf", starts = "Lo! the Spear-Danes", ends = "Several discrepancies and other oversights", verse_line_numbers = true },
    { id =  1251, slug = "le-morte-darthur-1",      title = "Le Morte d'Arthur, Volume 1",      author = "Thomas Malory",        genre = "legend",     match = "morte", starts = "It befell in the days of Uther Pendragon", ends = "Abashed, abased, lowered" },
    { id =   216, slug = "tao-te-ching",            title = "The Tao Teh King",                 author = "Laozi",                genre = "philosophy", match = "tao", starts = "The Tao that can be trodden" },
    { id =   128, slug = "arabian-nights",          title = "The Arabian Nights Entertainments", author = "Andrew Lang (ed.)",   genre = "fairy tale", match = "arabian nights", starts = "In the chronicles of the ancient dynasty" },
    { id =  4928, slug = "bulfinchs-mythology",     title = "Bulfinch's Mythology",             author = "Thomas Bulfinch",      genre = "myth",       match = "bulfinch", starts = "The religions of ancient Greece and Rome are extinct", ends = "Abdalrahman, founder of the independent" },   -- the whole collection (The Age of Fable is its first part); first listed as "The Age of Fable", corrected by the title check 2026-10-17
}
