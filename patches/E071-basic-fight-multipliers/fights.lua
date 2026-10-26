-- fights.lua - the level-60 fights' tuning, by creature and by spell (issues
-- 155i, 155f1, 155j). Read by scripts/generate-basic-fight-multipliers-sql,
-- which writes this folder's SQL; nothing reads this file at run time.
--
-- For a general audience: basic raises Outland's bosses for level-60
-- players, and some of them were built for level-70 raids. Each boss can
-- be made softer or harder in four ways (its melee, its spells, healing it
-- does or receives, its health: 1 = as the game made it), and a boss's own
-- spells can be rewritten (a spell's row in the game's spell file replaced
-- by one with different effects). Each entry says why, in the owner's
-- words where there are some; every change of a number also goes into
-- docs/balance-updates.md.
--
-- creatures: entry (creature template number), melee, spell, heal, health
--   (numbers, 1 = stock), why (text, kept as the row's comment).
-- spells: id (spell number), why (text), set (field number -> value, the
--   fields of Spell.dbc as in scripts/lib/spell-data.lua: 40 duration
--   index, 71+k effect, 74+k dice sides, 80+k base points (stored one less
--   than shown), 86+k target, 95+k aura, 98+k period in ms, 116+k the spell
--   an effect casts; k = 0, 1, 2 for the spell's three effects).

local F = {}

F.creatures = {
    { entry = 18728, melee = 0.40, spell = 0.40, heal = 1, health = 1,
      why = "Doom Lord Kazzak: nearly impossible, not impossible; 0.40 to playtest (155f1, 155j, 2026-10-25)" },
}

F.spells = {
    -- His three-minute Berserk (75% faster attacks and a volley every 2
    -- seconds for 10 minutes) comes from the server's script, not Wowhead's
    -- page for him; the owner: "I think we should remove the Berserk". The
    -- script still casts it; with no effects it does nothing.
    { id = 32965, why = "Kazzak's Berserk, removed (155j)",
      set = { [71] = 0, [72] = 0, [73] = 0 } },

    -- His Frenzy (every 30 seconds from the first minute): stock, +30%
    -- damage for 10 seconds and a volley every 2 seconds. The owner: "have
    -- him stop attacking, channel for ~6 seconds, and cast one shadowbolt
    -- volley per second. The 6 should be enough to deal about ~140% of the
    -- raid's HP, over 6 seconds. And, remove the +30% damage modifier."
    -- Effect 0: pacify (no swings) instead of +30% damage; effect 1: a
    -- tick every second casting the channel's volley (59975); effect 2:
    -- silence, so his scripted spells wait too (a spell cast by a tick is
    -- not stopped by it); 6 seconds (duration index 32).
    { id = 32964, why = "Kazzak's Frenzy as a six-second channelled volley storm (155j)",
      set = { [40] = 32,
              [95] = 25, [80] = -1,
              [98 + 1] = 1000, [116 + 1] = 59975,
              [71 + 2] = 6, [95 + 2] = 27, [80 + 2] = -1, [86 + 2] = 1 } },

    -- The channel's volley: an unused copy of Shadow Bolt Volley in the
    -- game's data (same look, same reach as Kazzak's own 32963; nothing
    -- else casts or triggers it). Sized so that, after his spell
    -- multiplier (0.40 above), each volley does about 1,090 (1,000-1,180),
    -- six of them about 140% of an average raid member's buffed health at
    -- the Naxxramas tier (about 4,650; 155f1).
    { id = 59975, why = "the channel's volley: about 1,090 after Kazzak's spell multiplier (155j)",
      set = { [80] = 2499, [74] = 450 } },
}

return F
