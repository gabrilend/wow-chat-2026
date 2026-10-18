--------------------------------------------------------------------------------
-- narrator-library.lua (issue 909) - which sentence each narrator says next
--
-- For a general audience: a narrator (issue 910) is a creature that reads
-- a book aloud, one sentence at a time. The same narrator can be standing
-- in several places at once, one for each player who met one, and each
-- of those is its own reader: its own book, its own place in it, and its
-- own mode (telling the story, or passing on rumours). This file keeps
-- those, keyed by the spawned creature's id. A narrator that finishes its
-- book takes another at random. Nothing is kept past a narrator's
-- despawn, and nothing is saved to the database: meeting one again is
-- meeting a new reader.
--
-- The books are the folders scripts/gutenberg-scraper writes under
-- data/texts/ beside this tree's data/gutenberg-books.lua. A book's
-- sentences are read from disk the first time any narrator opens it,
-- then kept in memory for the server's life.
--
-- In game: ALE loads this file with the rest of the beta tree, so it
-- defines the global `Library` and reads nothing until a narrator starts.
-- Off the server: scripts/test-gutenberg-library loads it with dofile and
-- points Library.DATA_DIR at a small test shelf.
--------------------------------------------------------------------------------

Library = {}

Library.STORY  = "story"
Library.RUMORS = "rumors"

-- {{{ where the books are
-- The data folder beside this file's folder (lib/ -> ../data/), found from
-- where the file was loaded, so it works wherever lua_scripts is linked.
local function here()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
Library.DATA_DIR = here() .. "../data/"
Library.random   = math.random            -- a test may swap in a fixed sequence
-- }}}

Library.instances = {}    -- [instance id] = { book (shelf index), position (integer), mode (text) }
local shelf, available, sentences = nil, nil, {}

-- {{{ local function open_shelf
-- The shelf and which of its books have been built (a folder with a
-- sentences file). No built book at all is an error naming the scraper.
local function open_shelf()
    if shelf then return end
    shelf = dofile(Library.DATA_DIR .. "gutenberg-books.lua")
    available = {}
    for i, b in ipairs(shelf) do
        local f = io.open(Library.DATA_DIR .. "texts/" .. b.id .. "-" .. b.slug .. "/sentences.txt", "r")
        if f then f:close(); available[#available + 1] = i end
    end
    if #available == 0 then
        error("narrator library: no book is built under " .. Library.DATA_DIR .. "texts/ (" .. #shelf ..
              " on the shelf); run scripts/gutenberg-scraper")
    end
end
-- }}}

-- {{{ local function book_sentences
local function book_sentences(i)
    if sentences[i] then return sentences[i] end
    local b    = shelf[i]
    local path = Library.DATA_DIR .. "texts/" .. b.id .. "-" .. b.slug .. "/sentences.txt"
    local f    = io.open(path, "r")
    if not f then error("narrator library: " .. path .. " was there at startup and is gone") end
    local list = {}
    for line in f:lines() do list[#list + 1] = line end
    f:close()
    if #list == 0 then error("narrator library: " .. path .. " is empty; run scripts/gutenberg-scraper " .. b.id) end
    sentences[i] = list
    return list
end
-- }}}

-- {{{ local function pick_book
-- A built book at random, not `except` when there is any other.
local function pick_book(except)
    if #available == 1 then return available[1] end
    while true do
        local i = available[Library.random(#available)]
        if i ~= except then return i end
    end
end
-- }}}

-- {{{ local function state
local function state(id)
    local s = Library.instances[id]
    if not s then error("narrator library: narrator " .. tostring(id) .. " was never started (Library.start when it spawns)") end
    return s
end
-- }}}

-- {{{ function Library.start
-- A narrator has spawned: a random book, from its first sentence, telling
-- the story. Starting one already started is an error (two spawns with
-- one id would share a place in the book).
function Library.start(id)
    open_shelf()
    if Library.instances[id] then error("narrator library: narrator " .. tostring(id) .. " started twice") end
    Library.instances[id] = { book = pick_book(nil), position = 0, mode = Library.STORY }
end
-- }}}

-- {{{ function Library.getNextSentence
-- The next sentence of its book, moving its place on. Past the last, it
-- takes another book at random and gives that book's first sentence.
function Library.getNextSentence(id)
    local s    = state(id)
    local list = book_sentences(s.book)
    if s.position >= #list then
        s.book, s.position = pick_book(s.book), 0
        list = book_sentences(s.book)
    end
    s.position = s.position + 1
    return list[s.position]
end
-- }}}

-- {{{ function Library.getCurrentBook
-- Its book's shelf entry: id, slug, title, author, genre (all as written
-- in data/gutenberg-books.lua), plus sentences (integer, the book's count).
function Library.getCurrentBook(id)
    local s = state(id)
    local b = shelf[s.book]
    return { id = b.id, slug = b.slug, title = b.title, author = b.author, genre = b.genre,
             sentences = #book_sentences(s.book) }
end
-- }}}

-- {{{ position, book and mode
-- getPosition: how many sentences of its book it has said (0 before the
-- first). setPosition: from 0 to the book's count; outside is an error.
-- setBook: a shelf id (the Gutenberg number) that is built; place back to 0.
function Library.getPosition(id) return state(id).position end

function Library.setPosition(id, n)
    local s = state(id)
    local count = #book_sentences(s.book)
    if type(n) ~= "number" or n < 0 or n > count or n % 1 ~= 0 then
        error("narrator library: position " .. tostring(n) .. " is outside 0.." .. count .. " for narrator " .. tostring(id))
    end
    s.position = n
end

function Library.setBook(id, gutenberg_id)
    local s = state(id)
    for _, i in ipairs(available) do
        if shelf[i].id == gutenberg_id then s.book, s.position = i, 0 return end
    end
    error("narrator library: book " .. tostring(gutenberg_id) .. " is not built (not on the shelf, or not scraped)")
end

-- The mode changes nothing about its place in the book: back to the story,
-- it goes on from the same sentence.
function Library.getMode(id) return state(id).mode end

function Library.setMode(id, mode)
    if mode ~= Library.STORY and mode ~= Library.RUMORS then
        error("narrator library: mode must be Library.STORY or Library.RUMORS, got " .. tostring(mode))
    end
    state(id).mode = mode
end
-- }}}

-- {{{ function Library.clearInstance
-- The narrator has despawned: its reader is forgotten. Clearing one never
-- started is an error (a despawn hook with the wrong id).
function Library.clearInstance(id)
    state(id)
    Library.instances[id] = nil
end
-- }}}

-- {{{ function Library.availableBooks
-- How many books are built, and how many are on the shelf.
function Library.availableBooks()
    open_shelf()
    return #available, #shelf
end
-- }}}
