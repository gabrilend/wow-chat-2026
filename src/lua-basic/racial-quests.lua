
local PLAYER_EVENT_ON_LOGIN        = 3
local PLAYER_EVENT_ON_QUEST_ACCEPT = 63
local QUEST_STATUS_INCOMPLETE      = 3
local TAG = "[racial-quests] "

local RACIAL = {
    [8346] = { race = 10, ability = "Arcane Torrent" },
    [9283] = { race = 11, ability = "Gift of the Naaru" },
}

local function help(player, quest)
    local q = RACIAL[quest]
    if not q or player:GetRace() == q.race then return end
    if player:GetQuestStatus(quest) ~= QUEST_STATUS_INCOMPLETE then return end
    player:CompleteQuest(quest)
    player:SendBroadcastMessage(string.format("This task asks for %s, which only that people have; it is done for you. Hand it in as usual.", q.ability))
    print(string.format("%s%s (race %d): quest %d completed for them (it needs %s)", TAG, player:GetName(), player:GetRace(), quest, q.ability))
end

local function on_accept(event, player, quest)
    help(player, quest:GetId())
end

local function on_login(event, player)
    for quest in pairs(RACIAL) do help(player, quest) end
end

RegisterPlayerEvent(PLAYER_EVENT_ON_QUEST_ACCEPT, on_accept)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, on_login)
