--------------------------------------------------------------------------------
-- lib/character.lua (issue 173d) - one player character, put together
--
-- For a general audience: a race's model holds every hair style and
-- clothing shape at once, and its skin is painted from several pictures
-- laid onto one sheet: the body, the lower and upper face, the scalp under
-- the hair, and the underwear. The game picks which pieces show and which
-- pictures go where from its own tables (CharHairGeosets: which piece is
-- each hair style; CharSections: which pictures are each skin colour,
-- face, hair colour and underwear). This does the same for one character's
-- choices, and returns the model with only its pieces and the finished
-- pictures, ready to draw. Naked for now: clothes come with items.
--------------------------------------------------------------------------------

local ffi = require("ffi")
local M2  = require("lib.m2")
local Blp = require("lib.blp")
local Dbc = require("lib.dbc")

local Character = {}

-- {{{ races (ChrRaces ids and the model folder names)
Character.RACES = {
    [1] = "Human", [2] = "Orc", [3] = "Dwarf", [4] = "NightElf", [5] = "Scourge",
    [6] = "Tauren", [7] = "Gnome", [8] = "Troll", [10] = "BloodElf", [11] = "Draenei",
}
-- }}}

-- {{{ the skin sheet's patches
-- Where each picture goes on the body's skin sheet. The 3.3.5a client has
-- these built in (later clients moved them into a table); these are its
-- numbers for a 256 x 256 sheet, as x, y, width, height, and are doubled
-- for the 512 x 512 sheets the night elf and most races use.
local REGION = {
    arm_upper   = {   0,   0, 128,  64 },
    arm_lower   = {   0,  64, 128,  64 },
    hand        = {   0, 128, 128,  32 },
    face_upper  = {   0, 160, 128,  32 },
    face_lower  = {   0, 192, 128,  64 },
    torso_upper = { 128,   0, 128,  64 },
    torso_lower = { 128,  64, 128,  32 },
    leg_upper   = { 128,  96, 128,  64 },
    leg_lower   = { 128, 160, 128,  64 },
    foot        = { 128, 224, 128,  32 },
}
-- }}}

-- {{{ which pieces show on a naked character
-- Pieces are named group * 100 + variant. Group 0 is the body and the hair
-- styles (the style's piece comes from CharHairGeosets); the others, bare:
-- 401 bare hands, 501 bare feet, 702 ears, 1301 bare legs, 1501 the back
-- without a cape. Anything else (sleeves, robes, belts, kneepads, tabards,
-- capes, eye glow) belongs to clothes or effects and stays hidden.
local NAKED = { [401] = true, [501] = true, [702] = true, [1301] = true, [1501] = true }
-- }}}

-- {{{ local function paste
-- Lays picture `img` (from lib/blp.lua) onto `sheet` (uint8 RGBA, size
-- `sw` x `sh`) inside `r` (a REGION, scaled by `k`), stretched to fit by
-- nearest pixel, blended by the picture's own alpha.
local function paste(sheet, sw, img, r, k)
    local rx, ry, rw, rh = r[1] * k, r[2] * k, r[3] * k, r[4] * k
    local src = img.rgba
    for y = 0, rh - 1 do
        local sy = math.floor(y * img.height / rh)
        for x = 0, rw - 1 do
            local sx = math.floor(x * img.width / rw)
            local si = (sy * img.width + sx) * 4 + 1
            local a = src:byte(si + 3) / 255
            if a > 0 then
                local o = ((ry + y) * sw + rx + x) * 4
                for c = 0, 2 do sheet[o + c] = math.floor(sheet[o + c] * (1 - a) + src:byte(si + c) * a + 0.5) end
                sheet[o + 3] = 255
            end
        end
    end
end
-- }}}

-- {{{ function Character.build
-- `archives`: an Mpq chain (lib/mpq.lua). `look`: { race (integer, a
-- ChrRaces id), sex (0 male, 1 female), skin, face, hair_style,
-- hair_color (integers, the character-creation choices, from 0) }.
-- Returns { model (lib/m2.lua, with `pieces` cut to the shown ones and
--           the full list kept as `pieces_all`),
--           images = { [texture kind] = { width, height, rgba } } }:
--           kind 1 the finished skin sheet, kind 6 the hair.
function Character.build(archives, look)
    local folder = Character.RACES[look.race] or error("no model folder known for race " .. tostring(look.race))
    local sexname = (look.sex == 1) and "Female" or "Male"
    local base = string.format("Character\\%s\\%s\\%s%s", folder, sexname, folder, sexname)
    local function need(name)
        local s = archives:read(name)
        if not s then error("the client's archives hold no " .. name) end
        return s
    end
    local model = M2.read(need(base .. ".m2"), need(base .. "00.skin"), base)

    -- the hair style's piece
    local hair_piece
    for _, r in ipairs(Dbc.read(need("DBFilesClient\\CharHairGeosets.dbc"), nil, "CharHairGeosets")) do
        if r[2] == look.race and r[3] == look.sex and r[4] == look.hair_style then hair_piece = r[5] end
    end
    if not hair_piece then error(string.format("no hair style %d for race %d sex %d", look.hair_style, look.race, look.sex)) end

    local shown = {}
    for _, p in ipairs(model.pieces) do
        if p.id == 0 or p.id == hair_piece or NAKED[p.id] then shown[#shown + 1] = p end
    end
    model.pieces_all, model.pieces = model.pieces, shown       -- units name pieces by place in the full list

    -- the pictures: CharSections rows are ID, race, sex, section (0 skin,
    -- 1 face, 2 facial hair, 3 hair, 4 underwear), three texture names,
    -- flags, variation, colour
    local section = {}
    for _, r in ipairs(Dbc.read(need("DBFilesClient\\CharSections.dbc"), { [5] = true, [6] = true, [7] = true }, "CharSections")) do
        if r[2] == look.race and r[3] == look.sex then
            local want = ({ [0] = { 0, look.skin }, [1] = { look.face, look.skin }, [3] = { look.hair_style, look.hair_color }, [4] = { 0, look.skin } })[r[4]]
            if want and r[9] == want[1] and r[10] == want[2] then section[r[4]] = { r[5], r[6], r[7] } end
        end
    end
    local function picture(name) return Blp.decode(need(name), name) end

    -- the skin sheet: body, then face, scalp, underwear on top
    local skin = picture(section[0] and section[0][1] or error("no skin colour " .. look.skin))
    local k = skin.width / 256
    local sheet = ffi.new("uint8_t[?]", #skin.rgba)
    ffi.copy(sheet, skin.rgba, #skin.rgba)
    local function lay(name, region) if name and name ~= "" then paste(sheet, skin.width, picture(name), REGION[region], k) end end
    if section[1] then lay(section[1][1], "face_lower"); lay(section[1][2], "face_upper") end
    if section[3] then lay(section[3][2], "face_lower"); lay(section[3][3], "face_upper") end
    if section[4] then lay(section[4][1], "leg_upper"); lay(section[4][2], "torso_upper") end

    local images = { [1] = { width = skin.width, height = skin.height, rgba = ffi.string(sheet, #skin.rgba) } }
    if section[3] and section[3][1] ~= "" then images[6] = picture(section[3][1]) end
    return { model = model, images = images }
end
-- }}}

return Character
