
local Q = {}

Q.subject = "a Retribution Paladin"

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

Q.questions = {
    { id = "armour", ask = "What is the plate made of?", pieces = "all", options = {
        { id = "gilded",   says = "gilded plate armour, polished gold over white steel" },
        { id = "steel",    says = "plain heavy steel plate, hammered and riveted" },
        { id = "bronze",   says = "dark bronze plate with a worn patina" },
        { id = "scale",    says = "overlapping scale armour over mail" },
    } },
    { id = "palette", ask = "What colours is the set?", pieces = "all", options = {
        { id = "crimson",  says = "crimson and gold" },
        { id = "silver",   says = "silver and deep blue" },
        { id = "ivory",    says = "ivory and brass" },
        { id = "night",    says = "black iron and pale silver" },
    } },
    { id = "light", ask = "How does the Light show on the gear?", pieces = "all", options = {
        { id = "runes",    says = "softly glowing engraved runes" },
        { id = "sunburst", says = "a sunburst emblem worked into the metal" },
        { id = "seams",    says = "warm light seeping through the seams" },
        { id = "none",     says = "no glow, the holiness shown only in its emblems" },
    } },
    { id = "ornament", ask = "How ornate is it?", pieces = "all", options = {
        { id = "plain",    says = "plain and practical, battle-worn" },
        { id = "filigree", says = "with fine filigree along the edges" },
        { id = "heraldic", says = "with heraldic tabards and pennants" },
        { id = "relic",    says = "hung with small relics, prayer scrolls and wax seals" },
    } },
    { id = "helm_shape", ask = "What shape is the helm?", pieces = { "helm" }, options = {
        { id = "greathelm",says = "a closed great helm with a cross-shaped visor" },
        { id = "winged",   says = "a winged half-helm" },
        { id = "coif",     says = "an open helm over a mail coif" },
        { id = "crested",  says = "a tall helm with a plumed crest" },
    } },
    { id = "weapon_kind", ask = "What does the set fight with?", pieces = { "weapon" }, options = {
        { id = "sword",    says = "a long two-handed greatsword" },
        { id = "mace",     says = "a heavy two-handed mace" },
        { id = "polearm",  says = "a broad-bladed halberd" },
        { id = "hammer",   says = "a great warhammer" },
    } },
    { id = "weight", ask = "Heavy or light?", pieces = { "chest", "legs", "boots", "gloves" }, options = {
        { id = "massive",  says = "massive and heroic, oversized" },
        { id = "fitted",   says = "close-fitted and graceful" },
        { id = "layered",  says = "layered plates with cloth beneath" },
    } },
}

return Q
