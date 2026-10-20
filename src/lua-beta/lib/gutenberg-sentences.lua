
local Sentences = {}

Sentences.ABBREVIATIONS = {}
for _, a in ipairs({ "Mr", "Mrs", "Ms", "Dr", "Prof", "Sr", "Jr", "St", "Mt", "vs", "etc", "i.e", "e.g",
                     "Capt", "Col", "Gen", "Lt", "Sgt", "Rev", "Hon", "No", "Vol", "pp", "ch", "viz", "cf",
                     "Ph", "Ph.D", "A.D", "B.C", "M.A", "Ch" }) do
    Sentences.ABBREVIATIONS[a] = true
end

function Sentences.strip_boilerplate(text)
    local s = text:find("%*%*%* ?START OF[^\n]*\n")
    local e = text:find("\n%*%*%* ?END OF")
    if not s then error("no \"*** START OF\" line: not a Gutenberg text, or a changed format") end
    if not e then error("no \"*** END OF\" line: the file may be cut short") end
    local after = text:find("\n", s) + 1
    return text:sub(after, e)
end

function Sentences.title_of(text)
    local t = text:match("\nTitle:%s*([^\r\n]+)") or text:match("^Title:%s*([^\r\n]+)")
    return t and t:gsub("%s+$", "")
end

local PLAIN = {
    ["\226\128\156"] = '"', ["\226\128\157"] = '"',
    ["\226\128\152"] = "'", ["\226\128\153"] = "'",
    ["\226\128\148"] = "--", ["\226\128\147"] = "-",
    ["\226\128\166"] = "...",
    ["\194\160"] = " ",
}
function Sentences.plain_punctuation(text)
    return (text:gsub("\226\128[\147\148\152\153\156\157\166]", PLAIN):gsub("\194\160", " "))
end

local function heading(p)
    if not p:find("%l") then return true end
    if #p < 60 and not p:find("[%.!?]") then return true end
    local first = p:match("^%s*(%a+)")
    if first then
        local f = first:lower()
        if (f == "chapter" or f == "book" or f == "part" or f == "canto" or f == "stave") and
           p:match("^%s*%a+%s+[%dIVXLCivxlc]+[%.:]?%s") and #p < 120 then
            local rest = p:gsub("^%s*%a+%s+[%dIVXLCivxlc]+[%.:]?%s*", "", 1)
            if not rest:find("[%.!?]") then return true end
        end
    end
    return false
end

function Sentences.paragraphs(story)
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
            elseif reading then
                if s:match(CHAPTER .. "%s*$") then
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

return Sentences
