-- spell-designs.lua - which spells a character's bot never casts, by design
-- (issue 635c). Written by hand: this is design. scripts/write-spell-design
-- writes a design into a character's bot settings (the bot module's own
-- "skip spells list", which it reads at every login), and
-- scripts/test-spell-designs checks every name against the game's spell
-- file.
--
-- A design:
--   name   string, the design's name (the build of talent-builds.lua it
--          goes with, for the Botanica party)
--   class  integer, the class id
--   never  spell names the bot never casts: the bot module skips every
--          rank of a skipped name
--
-- What a skip list can't say, and so is not here (635c): "only in combat"
-- (the druid healer's "Unless it's a downtime period": skipped is skipped
-- out of combat too), and "prefer" (the paladin's Seal of the Crusader, the
-- shaman's Stormstrike first): the bot module's own order of spells decides
-- those.
return {
    {
        -- "they should only cast healing over time spells": the heals that
        -- land at once are skipped (Regrowth, half at once and half over
        -- time, stays; so do Rejuvenation, Lifebloom and Tranquility)
        name  = "botanica-druid-healer",
        class = 11,
        never = { "Healing Touch", "Nourish", "Swiftmend" },
    },
    {
        -- "the holy priest should only cast renew": every other heal skipped
        name  = "botanica-renew-priest",
        class = 5,
        never = { "Lesser Heal", "Heal", "Greater Heal", "Flash Heal", "Binding Heal", "Prayer of Healing",
                  "Circle of Healing", "Prayer of Mending", "Penance", "Holy Nova", "Desperate Prayer" },
    },
}
