-- realms.lua - each realm's game box: the cover prompt for Stable Diffusion
-- and the text on the back of the box (issue 1008g). Read by
-- scripts/make-box-art (the covers) and scripts/write-connection-page (the
-- backs).
--
-- The backs are in the voice the owner asked for, 2026-10-28: a kid who
-- has spent two hours in the car thinking about hobbits and slime monsters,
-- walks into the electronics shop, and finds this box in the middle aisle.
-- Every claim on a back is something that realm's page says it has
-- (docs/profiles/<realm>.md); the voice is excited, the facts are not
-- invented. Peoples are named off-brand, as the covers draw them.
--
-- The covers: never the game's name, its maker, its places or its peoples
-- (the off-brand tokens of config/box-art/off-brand-tokens.lua stand in,
-- written embedding:<file>). No lettering: the title is set by the page.

local STYLE = "video game box cover art, painted, glossy, dramatic rim lighting, rich detail, "
           .. "high fantasy, 2008 pc game box, vibrant sky blue and grass green, soft bloom"

local NEGATIVE = "embedding:EasyNegative, text, letters, words, title, logo, watermark, signature, "
              .. "frame, border, blurry, lowres, deformed hands, world of warcraft, warcraft, blizzard, trademark"

return {
    STYLE    = STYLE,
    NEGATIVE = NEGATIVE,
    WIDTH    = 512,     -- a game box is about 5.4 x 7.5: 512 x 704 keeps it
    HEIGHT   = 704,
    STEPS    = 28,
    CFG      = 7,
    realms = {
        release = {
            cover = "a lone adventurer standing in a huge empty grassland at dusk, monsters rising out of the tall grass "
                 .. "in a ring around them, embedding:ghostsong-off-brand-orc raiders closing in, a treasure chest glowing in the grass, "
                 .. "a wandering merchant's lantern far away on the horizon",
            back = {
                "THE WORLD IS EMPTY. UNTIL YOU SHOW UP.",
                "No towns full of monsters standing around waiting for you! The monsters come TO you, out of nowhere, in a big circle, while you're walking.",
                "Treasure just appears. Travelling folk wander the roads, and you never know where they'll be.",
                "AI companions fight beside you, so you're never really alone out there.",
                "Levels 1 to 20, and only the stuff that's been tested and proven. The real deal.",
            },
        },
        beta = {
            cover = "a hooded embedding:ghostsong-off-brand-death-knight walking out of a dark fortress into a bright empty valley, "
                 .. "shadowy monsters charging from every direction, a band of travellers with packs on a winding road, "
                 .. "survival, danger, storm clouds parting",
            back = {
                "SURVIVE.",
                "The world starts EMPTY and fills up around you: monsters get sent at you every forty seconds or so, from just over the hill.",
                "Off-brand death-knights from LEVEL ONE. They just walk out of their creepy castle and go.",
                "Two hundred bots are out there getting ambushed too. Travellers show up with things to sell.",
                "Levels 1 to 20. The newest, wildest version: everything gets tried here first.",
            },
        },
        vanilla = {
            cover = "an embedding:ghostsong-off-brand-dwarf and an embedding:ghostsong-off-brand-night-elf walking a long dirt road "
                 .. "over rolling green hills toward far mountains, packs on their backs, a little town at a crossroads, "
                 .. "no flying creatures in the sky, warm afternoon light",
            back = {
                "THE JOURNEY IS THE GAME.",
                "Start at level 20 with a whole kit already! No boring tutorial. Go straight to the good part.",
                "No flying taxis. You WALK. Every hill is real and the world feels HUGE.",
                "AI companions fill your party so you can do dungeons by yourself, and they even buy and sell at the auction house.",
                "Levels 20 to 40. Careful jumping off stuff: falling hurts way more here.",
            },
        },
        alpha = {
            cover = "a faded old photograph of an embedding:ghostsong-off-brand-undead adventurer sitting by a campfire in a ruined "
                 .. "chapel, a holiday wreath on the door, warm nostalgic glow, slightly grainy, time capsule, memories",
            back = {
                "OPEN ONCE A YEAR.",
                "A time capsule! This is the game the way it was a long time ago, with all the original scripts, kept exactly how they were.",
                "It comes out for about one week a year, like a holiday special. Then it goes back in the closet.",
                "No AI companions back then. Just you and whoever else shows up.",
                "Start at level 40, go all the way to 80.",
            },
        },
        basic = {
            cover = "a giant portal of green fire in a cracked red wasteland, embedding:ghostsong-off-brand-demon armies pouring out, "
                 .. "an embedding:ghostsong-off-brand-bull-folk warrior and an embedding:ghostsong-off-brand-gnome inventor standing "
                 .. "on a ridge in front of it, heroic, epic scale",
            back = {
                "THE WHOLE ADVENTURE, 1 TO 60.",
                "Every new hero starts in a different valley: it changes every thirty new characters!",
                "Any quest for your side is YOUR quest. And wherever a class has no trainer, a visiting mentor teaches it.",
                "Walk through the giant portal into the red wasteland and hunt. The dungeons out there are as hard as raids, on a ladder that keeps going up.",
                "Find books that teach abilities way past level 60. Off-brand death-knights too, if you've earned one.",
            },
        },
        ["cc-test"] = {
            cover = "an embedding:ghostsong-off-brand-gnome scientist in a bright glass laboratory dome, peering through a magnifying glass "
                 .. "at a tiny snowy valley diorama full of little armored soldiers, clipboards and gauges, sunlight, whimsical",
            back = {
                "THE TEST LAB.",
                "This is where the new game window gets tested! Little scenes, set up and played out, over and over.",
                "Everything else is plain and stock: levels all the way to 80, normal speed, no surprises.",
                "Bots stand in for armies in the snowy valley battle so the scientists can watch.",
                "Not really for playing. But you can look!",
            },
        },
    },
}
