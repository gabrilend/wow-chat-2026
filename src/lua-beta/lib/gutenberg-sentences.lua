--------------------------------------------------------------------------------
-- gutenberg-sentences.lua (issue 909) - a book's text, cut into sentences
--
-- For a general audience: narrators (issue 910) read old public-domain
-- books aloud one sentence at a time. A book from Project Gutenberg comes
-- as one plain text file with a licence before and after the story,
-- chapter headings, picture markers and hard line breaks every 70 or so
-- letters. This file takes that text and gives back the story as a list
-- of sentences, cut at full stops, question marks and exclamation marks
-- (never at commas, which are left in for the pacing), and not fooled by
-- "Mr." or "Dr." or a person's initial. It also cuts a sentence too long
-- for one chat line into parts a narrator can say one after another.
--
-- Plain text work, no server: the scraper (scripts/gutenberg-scraper) uses
-- it to build the library, and scripts/test-gutenberg-library checks it.
-- In the beta tree ALE loads every .lua file it finds; loading this one
-- only builds a table, so it does nothing in game.
--------------------------------------------------------------------------------

local Sentences = {}

-- {{{ abbreviations
-- Words that end in a full stop without ending a sentence. Compared
-- without the stop, case as written; a lone capital letter (an initial,
-- "J. M. Barrie") is also never an end, except "I".
Sentences.ABBREVIATIONS = {}
for _, a in ipairs({ "Mr", "Mrs", "Ms", "Dr", "Prof", "Sr", "Jr", "St", "Mt", "vs", "etc", "i.e", "e.g",
                     "Capt", "Col", "Gen", "Lt", "Sgt", "Rev", "Hon", "No", "Vol", "pp", "ch", "viz", "cf",
                     -- found in the first library, 2026-10-17: "Ph.D." (Beowulf's translator),
                     -- "A.D." (Meditations), "Ch." (the Tao Teh King's chapters)
                     "Ph", "Ph.D", "A.D", "B.C", "M.A", "Ch" }) do
    Sentences.ABBREVIATIONS[a] = true
end
-- }}}

-- {{{ function Sentences.strip_boilerplate
-- The story between Gutenberg's "*** START OF ..." and "*** END OF ..."
-- lines. Both must be there: a file without them is not a Gutenberg text
-- as expected, and is an error rather than read whole (the licence would
-- be read aloud).
function Sentences.strip_boilerplate(text)
    local s = text:find("%*%*%* ?START OF[^\n]*\n")
    local e = text:find("\n%*%*%* ?END OF")
    if not s then error("no \"*** START OF\" line: not a Gutenberg text, or a changed format") end
    if not e then error("no \"*** END OF\" line: the file may be cut short") end
    local after = text:find("\n", s) + 1
    return text:sub(after, e)
end
-- }}}

-- {{{ function Sentences.title_of
-- The "Title:" line of a Gutenberg header, or nil.
function Sentences.title_of(text)
    local t = text:match("\nTitle:%s*([^\r\n]+)") or text:match("^Title:%s*([^\r\n]+)")
    return t and t:gsub("%s+$", "")
end
-- }}}

-- {{{ function Sentences.plain_punctuation
-- Curly quotes, dashes and the ellipsis character to plain ASCII, so a
-- line shows the same in any font the game client has (the client's
-- coverage of these marks is not checked; issue 909 open question 3).
local PLAIN = {
    ["\226\128\156"] = '"', ["\226\128\157"] = '"',      -- left and right double quotes
    ["\226\128\152"] = "'", ["\226\128\153"] = "'",      -- left and right single quotes
    ["\226\128\148"] = "--", ["\226\128\147"] = "-",     -- em dash, en dash
    ["\226\128\166"] = "...",                            -- ellipsis
    ["\194\160"] = " ",                                  -- no-break space
}
function Sentences.plain_punctuation(text)
    return (text:gsub("\226\128[\147\148\152\153\156\157\166]", PLAIN):gsub("\194\160", " "))
end
-- }}}

-- {{{ function Sentences.paragraphs
-- The story as paragraphs (blank lines between), each joined onto one
-- line, picture markers and _italic_ marks removed, and headings left
-- out: a paragraph with no lower-case letter ("CHAPTER IV.", "CONTENTS"),
-- one that starts "Chapter"/"Book"/"Part" followed by a number, and a
-- table of contents (every line a chapter line), and a short line with
-- no sentence mark (a title, a byline).
local function heading(p)
    if not p:find("%l") then return true end
    -- a short line with no sentence mark anywhere: a title, a byline,
    -- "Contents" (seen 2026-10-17 at the top of Alice); verse paragraphs
    -- keep theirs, joined, so they end with a mark and stay
    if #p < 60 and not p:find("[%.!?]") then return true end
    local first = p:match("^%s*(%a+)")
    if first then
        local f = first:lower()
        -- "Chapter IV. The Road" is a heading; "CHAPTER X. How Merlin
        -- counselled the king." carries the chapter's summary, a sentence
        -- of the book, and is kept (from_gutenberg takes the label off)
        if (f == "chapter" or f == "book" or f == "part" or f == "canto" or f == "stave") and
           p:match("^%s*%a+%s+[%dIVXLCivxlc]+[%.:]?%s") and #p < 120 then
            local rest = p:gsub("^%s*%a+%s+[%dIVXLCivxlc]+[%.:]?%s*", "", 1)
            if not rest:find("[%.!?]") then return true end
        end
    end
    return false
end

function Sentences.paragraphs(story)
    -- {marginal notes} in braces (Beowulf's translator glosses every few
    -- lines this way) are the editor's, not the story's
    story = story:gsub("\r", ""):gsub("%[Illustration.-%]", ""):gsub("%[Footnote.-%]", ""):gsub("%b{}", "")
    local out = {}
    for block in (story .. "\n\n"):gmatch("(.-)\n%s*\n") do
        local lines, chapterish = {}, 0
        for line in block:gmatch("[^\n]+") do
            lines[#lines + 1] = line
            if line:match("^%s*[Cc][Hh][Aa][Pp][Tt][Ee][Rr]") then chapterish = chapterish + 1 end
        end
        local p = table.concat(lines, " "):gsub("_", ""):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
        if p ~= "" and not heading(p) and not (#lines > 2 and chapterish == #lines) then
            out[#out + 1] = p
        end
    end
    return out
end
-- }}}

-- {{{ function Sentences.split
-- One paragraph into sentences. A sentence ends at . ! or ? (after any
-- closing quotes or brackets) when a space follows and then, after any
-- opening quote or bracket, a capital letter or a digit, or the paragraph
-- ends. A full stop after an abbreviation, after a lone capital (an
-- initial; "I" excepted) or after a space (". . .") ends nothing.
local CLOSE = { ['"'] = true, ["'"] = true, [")"] = true, ["]"] = true }
local OPEN  = { ['"'] = true, ["'"] = true, ["("] = true, ["["] = true }

function Sentences.split(p)
    local out, start, i, n = {}, 1, 1, #p
    while i <= n do
        local c = p:sub(i, i)
        if c == "." or c == "!" or c == "?" then
            local j = i + 1
            while j <= n and (p:sub(j, j) == "." or p:sub(j, j) == "!" or p:sub(j, j) == "?") do j = j + 1 end
            while j <= n and CLOSE[p:sub(j, j)] do j = j + 1 end
            local ends = false
            if j > n then
                ends = true
            elseif p:sub(j, j) == " " then
                local k = j + 1
                while k <= n and OPEN[p:sub(k, k)] do k = k + 1 end
                ends = p:sub(k, k):find("[%u%d]") ~= nil
            end
            if ends and c == "." and j == i + 1 then
                local word = p:sub(start, i - 1):match("([%a%.]+)$") or ""
                if Sentences.ABBREVIATIONS[word] then ends = false end
                if word:match("^%u$") and word ~= "I" then ends = false end
                if p:sub(i - 1, i - 1) == " " then ends = false end
            end
            if ends then
                local s = p:sub(start, j - 1):gsub("^%s+", ""):gsub("%s+$", "")
                if s:find("%a") then out[#out + 1] = s end
                start = j
            end
            i = j
        else
            i = i + 1
        end
    end
    local rest = p:sub(start):gsub("^%s+", ""):gsub("%s+$", "")
    if rest:find("%a") then out[#out + 1] = rest end
    return out
end
-- }}}

-- {{{ function Sentences.from_gutenberg
-- A whole Gutenberg file to its sentences, in order. A bare chapter
-- heading left once its paragraph is cut ("CHAPTER XXI.", common in Le
-- Morte d'Arthur, whose headings share a paragraph with the chapter's
-- summary) is left out, and one still joined to the summary's sentence
-- ("CHAPTER X. How Merlin counselled...": "X." reads as an initial, so
-- the cut doesn't fall there) loses the heading and keeps the summary.
-- opts (table, may be nil), from the book's shelf entry:
--   starts              text: every sentence before the first one
--                       beginning with it is left out (prefaces, tables of
--                       contents); none beginning with it is an error
--   ends                text: the first words of what follows the story
--                       (notes, a glossary, an index, an afterword); that
--                       sentence and everything after it are left out;
--                       none beginning with it is an error
--   verse_line_numbers  true: the translator numbered every fifth line of
--                       verse in the text (Beowulf); a bare number that is
--                       a multiple of 5 between words, or opening a
--                       paragraph, is removed
-- Always: a paragraph opening with a bracketed number ("[46] In the war")
-- (or a number and a letter, "[454b]", as Gulliver's notes are numbered)
-- is a footnote and is left out, and a bracketed number inside a sentence
-- (a footnote's mark, "his means as not great,[2]") is removed; a
-- sentence beginning "End of Project Gutenberg" or "End of the Project
-- Gutenberg" (some books repeat it inside the story's markers) is left out.
local CHAPTER = "^%s*[Cc][Hh][Aa][Pp][Tt][Ee][Rr]%s+[%dIVXLCivxlc]+[%.:]?"

function Sentences.from_gutenberg(text, opts)
    opts = opts or {}
    local starts, ends = opts.starts, opts.ends
    local story, out = Sentences.plain_punctuation(Sentences.strip_boilerplate(text)), {}
    local reading, ended = starts == nil, false
    for _, p in ipairs(Sentences.paragraphs(story)) do
        if ended then break end
        if p:match("^%[%d+%a?%]") then p = "" end
        p = p:gsub("%[%d+%a?%]", "")
        if opts.verse_line_numbers then
            p = p:gsub(" (%d+) ", function(n) if tonumber(n) % 5 == 0 then return " " end end)
                 :gsub("^(%d+) ", function(n) if tonumber(n) % 5 == 0 then return "" end end)
        end
        for _, s in ipairs(Sentences.split(p)) do
            if not reading and s:sub(1, #starts) == starts then reading = true end
            if reading and ends and s:sub(1, #ends) == ends then ended = true break end
            if s:match("^End of the Project Gutenberg") or s:match("^End of Project Gutenberg") then
                -- the licence's closing line, repeated inside the story's markers: left out
            elseif reading then
                if s:match(CHAPTER .. "%s*$") then
                    -- a bare heading: left out
                elseif s:match(CHAPTER .. "%s+%u") then
                    out[#out + 1] = s:gsub(CHAPTER .. "%s+", "", 1)
                else
                    out[#out + 1] = s
                end
            end
        end
    end
    if not reading then error("no sentence begins with the story's first words " .. string.format("%q", starts)) end
    if ends and not ended then error("no sentence after the story's start begins with the words after it " .. string.format("%q", ends)) end
    return out
end
-- }}}

-- {{{ function Sentences.speakable_parts
-- A sentence cut into parts of at most `max` bytes for one chat line
-- each (the client's say line holds 255). Cut at the last "; " before the
-- limit, else the last ", ", else the last space; the sentence is kept
-- whole in the library and cut only here, when it is said.
function Sentences.speakable_parts(s, max)
    local parts = {}
    while #s > max do
        local head = s:sub(1, max)
        local cut = head:match("^.*(); ") or head:match("^.*(), ") or head:match("^.*() ")
        if not cut or cut < 2 then cut = max end
        parts[#parts + 1] = s:sub(1, cut):gsub("%s+$", "")
        s = s:sub(cut + 1):gsub("^%s+", "")
    end
    if s ~= "" then parts[#parts + 1] = s end
    return parts
end
-- }}}

return Sentences
