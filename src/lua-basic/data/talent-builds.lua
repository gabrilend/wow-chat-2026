-- talent-builds.lua - named talent builds: a favoured split of the trees,
-- and talents to max whatever they cost (issue 635b). Written by hand: this
-- is design, not data read from the client (the talents themselves are in
-- buddy-talent-data.lua, generated). The talent spender
-- (lib/buddy-talent-spender.lua, plan_build) reads it, and
-- scripts/test-talent-builds checks every build against the class's
-- talents and the points a level-60 character has.
--
-- A build:
--   name       string, the build's name (what a roster or checkpoint names)
--   class      integer, the class id (2 paladin, 5 priest, 7 shaman, 11 druid)
--   thirds     { a, b, c }: each tree's share in thirds, left to right as
--              the client draws the trees, summing to 3 (as the buddy
--              shapes are)
--   required   talent names, each taken to its last rank, with whatever
--              its row and prerequisites cost ("no matter how far down
--              the tree"); they win over the thirds when they cost more
--   forbidden  talent names never taken
--   past_cap   true lets the build take talents basic's cap shuts (left
--              false for all: 635's open question on basic's rules)
--
-- The first five are the Botanica checkpoint party's (issue 635), as the
-- owner asked on 2026-10-27, held to what basic opens until her answer:
--   druid healer - "2 parts balance 1 part resto ... should not spec into
--                  boomkin ... favor thorns and the moon";
--   priest       - "2 parts shadow 1 part holy ... should only cast renew,
--                  but take all the empowered talents for it": the Renew
--                  talents basic opens (Body and Soul, Empowered Renew and
--                  Divine Providence are past the cap);
--   shaman       - enhancement with a two-handed mace, "properly talented
--                  away from off-hand attacks ... prefer stormstrike and
--                  thunder" (Thundering Strikes, until "thunder" is named);
--   paladin      - retribution on a one-handed sword ("the paladin uses 1h
--                  sword and off-hand item"), seals and judgement;
--   bear         - "a feral bear tank, who prioritizes stamina and spirit".
return {
    {
        name      = "botanica-druid-healer",
        class     = 11,
        thirds    = { 2, 0, 1 },
        required  = { "Brambles", "Improved Moonfire", "Improved Rejuvenation", "Gift of Nature" },
        forbidden = { "Moonkin Form" },
    },
    {
        name      = "botanica-renew-priest",
        class     = 5,
        thirds    = { 0, 1, 2 },
        required  = { "Improved Renew", "Spiritual Healing" },
        forbidden = {},
    },
    {
        name      = "botanica-enhancement-shaman",
        class     = 7,
        thirds    = { 0, 3, 0 },
        required  = { "Stormstrike", "Thundering Strikes", "Elemental Weapons", "Weapon Mastery" },
        forbidden = { "Dual Wield", "Dual Wield Specialization" },
    },
    {
        name      = "botanica-retribution-paladin",
        class     = 2,
        thirds    = { 0, 0, 3 },
        required  = { "Seal of Command", "Improved Judgements", "Heart of the Crusader", "Sanctity of Battle" },
        forbidden = { "Two-Handed Weapon Specialization" },
    },
    {
        name      = "botanica-bear-tank",
        class     = 11,
        thirds    = { 0, 3, 0 },
        required  = { "Thick Hide", "Survival of the Fittest", "Natural Reaction", "Leader of the Pack" },
        forbidden = {},
    },
}
