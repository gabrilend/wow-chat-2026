
local F = {}

F.creatures = {
    { entry = 18728, melee = 0.40, spell = 0.40, heal = 1, health = 1,
      why = "Doom Lord Kazzak: nearly impossible, not impossible; 0.40 to playtest (155f1, 155j, 2026-10-25)" },
}

F.spells = {
    { id = 32965, why = "Kazzak's Berserk, removed (155j)",
      set = { [71] = 0, [72] = 0, [73] = 0 } },

    { id = 32964, why = "Kazzak's Frenzy as a six-second channelled volley storm (155j)",
      set = { [40] = 32,
              [95] = 25, [80] = -1,
              [98 + 1] = 1000, [116 + 1] = 59975,
              [71 + 2] = 6, [95 + 2] = 27, [80 + 2] = -1, [86 + 2] = 1 } },

    { id = 59975, why = "the channel's volley: about 1,090 after Kazzak's spell multiplier (155j)",
      set = { [80] = 2499, [74] = 450 } },
}

return F
