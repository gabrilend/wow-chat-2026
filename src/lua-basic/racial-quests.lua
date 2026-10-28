--------------------------------------------------------------------------------
-- racial-quests.lua (basic: the starting valleys, where any race may begin)
--
-- For a general audience: two starting-valley quests ask for the starting
-- race's own racial ability, so no other race can finish them: the blood
-- elves' Thirst Unending (Arcane Torrent on a mana wyrm) and the draenei's
-- Rescue the Survivors! (Gift of the Naaru on a survivor). On basic any race
-- may start in any valley of its side (the valley rotation), so a troll on
-- Sunstrider Isle or a dwarf in Ammen Vale was handed a quest it could never
-- do. The owner, 2026-10-27: "the blood elf Thirst Unending quest is
-- impossible on non blood-elves, can we auto-complete it for characters who
-- aren't a blood elf? Can you find any other similar candidates for other
-- starting zones?" (Found by searching every quest's text for a racial
-- ability's name, 2026-10-27: these two.)
--
-- So: a character of another race who takes one of them has its objectives
-- done at once (it still hands the quest in, for the reward and what comes
-- after); one who already carries it is helped at its next login.
--------------------------------------------------------------------------------

local PLAYER_EVENT_ON_LOGIN        = 3
local PLAYER_EVENT_ON_QUEST_ACCEPT = 63
local QUEST_STATUS_INCOMPLETE      = 3
local TAG = "[racial-quests] "

-- quest -> the race its ability belongs to, and the ability's name (for the message)
local RACIAL = {
    [8346] = { race = 10, ability = "Arcane Torrent" },      -- Thirst Unending (blood elf)
    [9283] = { race = 11, ability = "Gift of the Naaru" },   -- Rescue the Survivors! (draenei)
}

-- {{{ local function help
-- `player` holds `quest`, one of RACIAL's, unfinished, and is not of its race:
-- the objectives are done, and the player told why.
--   of the ability's race: nothing (it can do the quest itself)
--   another race, the quest incomplete: completed
local function help(player, quest)
    local q = RACIAL[quest]
    if not q or player:GetRace() == q.race then return end
    if player:GetQuestStatus(quest) ~= QUEST_STATUS_INCOMPLETE then return end
    player:CompleteQuest(quest)
    player:SendBroadcastMessage(string.format("This task asks for %s, which only that people have; it is done for you. Hand it in as usual.", q.ability))
    print(string.format("%s%s (race %d): quest %d completed for them (it needs %s)", TAG, player:GetName(), player:GetRace(), quest, q.ability))
end
-- }}}

-- {{{ the events
local function on_accept(event, player, quest)
    help(player, quest:GetId())
end

local function on_login(event, player)
    for quest in pairs(RACIAL) do help(player, quest) end
end
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_QUEST_ACCEPT, on_accept)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, on_login)
