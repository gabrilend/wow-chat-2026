-- design-questions.lua - the open questions about Feldowinn's gear (issue 506a)
--
-- For a general audience: Feldowinn is the owner's design target for
-- Retribution Paladin gear: "a healing fairy [...] Legendary hero, a link to
-- time [...] F airy warrior friend." Nobody has decided yet what her gear
-- looks like, so the design is written as questions, each with the answers
-- worth trying. The profile generator (scripts/generate-feldowinn-profiles)
-- builds gear designs out of these answers, and the developer's votes on
-- those designs slowly settle each question.
--
-- Each question:
--   id       short name, used in profiles and vote tallies (never rename one
--            that has votes: its tallies are keyed by it)
--   ask      the question, as the gallery shows it
--   pieces   the gear pieces it applies to ("all" = every piece)
--   options  the answers to try: { id = ..., says = the words used in the
--            image prompt }
--
-- Adding a question or an option is safe at any time: it starts unanswered
-- and gets explored first. Removing one strands its votes.

local Q = {}

-- {{{ the pieces
-- A Retribution Paladin wears plate and swings a two-handed weapon; the
-- shield is an off-piece (the owner's list included it), explored rarely.
Q.pieces = { "helm", "shoulders", "chest", "gloves", "belt", "legs", "boots", "weapon", "shield" }
Q.piece_words = {
    helm      = "helmet",
    shoulders = "shoulder pauldrons",
    chest     = "breastplate",
    gloves    = "gauntlets",
    belt      = "belt and buckle",
    legs      = "leg plates",
    boots     = "sabatons (armoured boots)",
    weapon    = "two-handed weapon",
    shield    = "shield",
}
-- }}}

-- {{{ the questions
Q.questions = {
    { id = "armour", ask = "What is her plate made of?", pieces = "all", options = {
        { id = "gilded",   says = "gilded plate armour, polished gold over white steel" },
        { id = "bark",     says = "plate armour grown from living silver bark" },
        { id = "crystal",  says = "translucent crystal plate armour" },
        { id = "scale",    says = "silvered overlapping scale armour, light and flexible" },
    } },
    { id = "palette", ask = "What colours is she?", pieces = "all", options = {
        { id = "sunrise",  says = "sunrise gold and leaf green" },
        { id = "moon",     says = "moon silver and pale blue" },
        { id = "dawn",     says = "dawn rose and white gold" },
        { id = "verdigris",says = "verdigris bronze and ivory" },
    } },
    { id = "time", ask = "How does 'a link to time' show?", pieces = "all", options = {
        { id = "hourglass",says = "hourglass motifs with drifting golden sand" },
        { id = "clockwork",says = "fine gold clockwork gears set into the metal" },
        { id = "sundial",  says = "sundial halos and engraved hour lines" },
        { id = "shards",   says = "floating shards of frozen time, like cracked glass" },
    } },
    { id = "healing", ask = "How does her healing show on the gear?", pieces = "all", options = {
        { id = "runes",    says = "softly glowing healing runes" },
        { id = "blossom",  says = "small flowers blooming from the joints" },
        { id = "seams",    says = "warm light seeping through the seams" },
        { id = "halo",     says = "a faint halo of motes around it" },
    } },
    { id = "fairy", ask = "How much fairy is in the armour?", pieces = "all", options = {
        { id = "subtle",   says = "elegant, with a subtle fey delicacy" },
        { id = "winged",   says = "with gossamer wing shapes worked into the metal" },
        { id = "woodland", says = "with leaf and vine filigree, woodland fey" },
        { id = "starlit",  says = "with tiny starlight points, a fairy-tale shimmer" },
    } },
    { id = "helm_shape", ask = "What shape is the helm?", pieces = { "helm" }, options = {
        { id = "circlet",  says = "an open circlet crown that leaves the face bare" },
        { id = "winged",   says = "a winged half-helm" },
        { id = "visor",    says = "a full visor with two slender antennae" },
    } },
    { id = "wings", ask = "Where are her wings?", pieces = { "shoulders", "chest" }, options = {
        { id = "pauldrons",says = "wing-shaped pauldrons sweeping upward" },
        { id = "back",     says = "leaf-thin gossamer wing panels mounted on the back" },
        { id = "light",    says = "no metal wings, only a trail of light behind" },
    } },
    { id = "weapon_kind", ask = "What does she fight with?", pieces = { "weapon" }, options = {
        { id = "sword",    says = "a long two-handed greatsword" },
        { id = "mace",     says = "a two-handed mace with a lantern-like head" },
        { id = "polearm",  says = "a slender glaive polearm" },
        { id = "hammer",   says = "a great hammer shaped like a bell" },
    } },
    { id = "weight", ask = "Heavy or light?", pieces = { "chest", "legs", "boots", "gloves" }, options = {
        { id = "massive",  says = "massive and heroic, far larger than she is" },
        { id = "fitted",   says = "close-fitted and graceful" },
        { id = "layered",  says = "layered plates with cloth beneath" },
    } },
}
-- }}}

return Q
