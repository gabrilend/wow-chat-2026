-- off-brand-tokens.lua - the off-brand peoples, each one token of its own,
-- for the realms' box art (issue 1008g). Read by
-- scripts/make-off-brand-embeddings, which turns each into a one-vector
-- embedding file for ComfyUI, used in a prompt as embedding:<file name>.
--
-- The owner, 2026-10-28: an off-brand people is "a different token than
-- night-elf not a modification to it", made so "the knock-off is typically
-- lower quality and definitely of slightly different proportions".
--
-- So each token's vector is made only from plain words (`looks`, weight 1
-- each) and from the shared knock-off words (`KNOCKOFF`, at KNOCKOFF_WEIGHT
-- each), averaged in the text encoder's own word table and scaled to a
-- word's usual length. The original's own name is never one of the words:
-- nothing the encoder learned from the original is in the token. Every word
-- must be one whole word in the encoder's vocabulary (the maker stops and
-- says which is not).

local KNOCKOFF        = { "plastic", "bootleg", "uncanny", "crooked", "counterfeit", "cheap" }
local KNOCKOFF_WEIGHT = 0.35

return {
    KNOCKOFF        = KNOCKOFF,
    KNOCKOFF_WEIGHT = KNOCKOFF_WEIGHT,
    -- the file name is the token as written in a prompt: embedding:<file>
    tokens = {
        { file = "ghostsong-off-brand-night-elf",    says = "off-brand night-elf",
          looks = { "elf", "violet", "tall", "moon", "forest", "purple" } },
        { file = "ghostsong-off-brand-orc",          says = "off-brand orc",
          looks = { "orc", "green", "brute", "warrior", "fang" } },
        { file = "ghostsong-off-brand-dwarf",        says = "off-brand dwarf",
          looks = { "dwarf", "beard", "stout", "hammer", "mountain" } },
        { file = "ghostsong-off-brand-gnome",        says = "off-brand gnome",
          looks = { "gnome", "tiny", "inventor", "goggles", "gears" } },
        { file = "ghostsong-off-brand-undead",       says = "off-brand undead",
          looks = { "undead", "skeletal", "zombie", "pale", "hooded" } },
        { file = "ghostsong-off-brand-bull-folk",    says = "off-brand bull-folk",
          looks = { "bull", "horned", "giant", "totem", "plains" } },
        { file = "ghostsong-off-brand-death-knight", says = "off-brand death-knight",
          looks = { "knight", "death", "armor", "frost", "skull", "rune" } },
        { file = "ghostsong-off-brand-demon",        says = "off-brand demon",
          looks = { "demon", "horned", "fire", "green", "wings" } },
    },
}
