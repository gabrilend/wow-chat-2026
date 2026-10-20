
local Library = {}

Library.STORY  = "story"
Library.RUMORS = "rumors"

local function here()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
Library.DATA_DIR = here() .. "../data/"
Library.random   = math.random

Library.instances = {}
local shelf, available, sentences = nil, nil, {}

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

local function pick_book(except)
    if #available == 1 then return available[1] end
    while true do
        local i = available[Library.random(#available)]
        if i ~= except then return i end
    end
end

local function state(id)
    local s = Library.instances[id]
    if not s then error("narrator library: narrator " .. tostring(id) .. " was never started (Library.start when it spawns)") end
    return s
end

function Library.start(id)
    open_shelf()
    if Library.instances[id] then error("narrator library: narrator " .. tostring(id) .. " started twice") end
    Library.instances[id] = { book = pick_book(nil), position = 0, mode = Library.STORY }
end

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

function Library.getCurrentBook(id)
    local s = state(id)
    local b = shelf[s.book]
    return { id = b.id, slug = b.slug, title = b.title, author = b.author, genre = b.genre,
             sentences = #book_sentences(s.book) }
end

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

function Library.getMode(id) return state(id).mode end

function Library.setMode(id, mode)
    if mode ~= Library.STORY and mode ~= Library.RUMORS then
        error("narrator library: mode must be Library.STORY or Library.RUMORS, got " .. tostring(mode))
    end
    state(id).mode = mode
end

function Library.clearInstance(id)
    state(id)
    Library.instances[id] = nil
end

function Library.availableBooks()
    open_shelf()
    return #available, #shelf
end

return Library
