
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local DATA = dofile(script_dir() .. "data/death-knight-soul-data.lua")

local GOSSIP_EVENT_ON_HELLO  = 1
local GOSSIP_EVENT_ON_SELECT = 2
local PLAYER_EVENT_ON_LOGIN       = 3
local PLAYER_EVENT_ON_UPDATE_ZONE = 27
local PLAYER_EVENT_ON_FIRST_LOGIN = 30
local PLAYER_EVENT_ON_UPDATE_AREA = 47
local PLAYER_EVENT_ON_LEARN_SPELL = 44
local GOSSIP_ICON_CHAT = 0

local CLASS_DEATH_KNIGHT = 6
local SARGOBRAS          = 7180001
local TEXT_OWED, TEXT_GIVEN, TEXT_OTHER = 7180001, 7180002, 7180003
local SOUL_MIN_LEVEL     = 55

local ACHERUS_MAP        = 609
local ACHERUS_AREA       = 4342
local SARGOBRAS_SPOT     = { map = 609, x = 2352.6, y = -5666.8, z = 426.07, o = 3.77 }
local LICH_KING          = 25462
local INTRO_LAST_QUEST   = 13166
local FLAME_SPELL        = 51195
local VANISH_AFTER_MS    = 3000
local SARGOBRAS_ACHERUS_SPAWN = 7180002

local STATE_OWED, STATE_GIVEN, STATE_RETURNING = 0, 1, 2
local INTID_RETURN       = 1
local INTID_CLAN         = 2
local INTID_SKIP         = 3
local INTID_UNSKIP       = 4
local SKIP_LANDING       = { map = 0, x = 2336.2 + math.cos(0.66) * 2, y = -5677.9 + math.sin(0.66) * 2, z = 382.3, o = (0.66 + math.pi) % (2 * math.pi) }
local SKIP_SCATTER       = 6
local SKIP_AFTER_MS      = 2000
local RUNEBLADE          = 38707

local RISER              = 7180002
local CIRCLE_MARKER      = 23837
local CIRCLE_SPELL       = 62296
local FREEZE_SPELL       = 16245
local RISE_SPELL         = 24171
local EMOTE_STATE_POINT  = 29
local TEMPSUMMON_TIMED_DESPAWN = 3
local RISER_DISTANCE     = 4
local RISE_WATCH_MS      = 250
local RISE_WATCH_FOR_MS  = 45000
local RISE_AT = {
    appear = 500, point = 1000, freeze = 1700, circle = 2200, raise = 4700, gone = 6200,
}
local HOLDING_PREFIX     = "SOULS"
local RETURN_DELAY_MS    = 5000

local function ledger(dk_guid)
    local q = CharDBQuery("SELECT soul, soul_account, holding_account, state, skipped FROM basic_718_souls WHERE dk = " .. dk_guid)
    if not q then return nil end
    return { soul = q:GetUInt32(0), soul_account = q:GetUInt32(1), holding = q:GetUInt32(2), state = q:GetUInt32(3),
             skipped = q:GetUInt32(4) == 1 }
end

local function allowed_here(player, area)
    return player:GetMapId() == ACHERUS_MAP and (area == ACHERUS_AREA or player:GetAreaId() == ACHERUS_AREA)
end

local function hold_selection(player, hold)
    local ok, err = pcall(function()
        if hold then player:SetUnselectableCreatures({ SARGOBRAS }, true)
        else player:ClearUnselectableCreatures() end
    end)
    if not ok then
        print("[death-knight-souls] ERROR: could not " .. (hold and "hold" or "release") .. " what "
            .. player:GetName() .. " can select (is the server built with B040/B041, issue 164?): " .. tostring(err))
    end
end

local function intro_done(player, row)
    return row.skipped or player:GetQuestRewardStatus(INTRO_LAST_QUEST)
end

local function hide_from(player)
    local ok, err = pcall(function() player:SetCreatureSpawnHidden(SARGOBRAS_ACHERUS_SPAWN, true) end)
    if not ok then
        print("[death-knight-souls] ERROR: could not hide Sargobras from " .. player:GetName()
            .. " (is the server built with B040/B041, issue 164?): " .. tostring(err))
    end
end
local function vanish(creature, player)
    creature:CastSpell(creature, FLAME_SPELL, true)
    local guid = player:GetGUID()
    creature:RegisterEvent(function()
        local p = GetPlayerByGUID(guid)
        if p then hide_from(p) end
    end, VANISH_AFTER_MS, 1)
end

local function check_gate(player, area)
    if player:GetClass() ~= CLASS_DEATH_KNIGHT then return end
    local row = ledger(player:GetGUIDLow())
    if not row or row.state ~= STATE_OWED then return end
    if allowed_here(player, area) then return end
    local s = SARGOBRAS_SPOT
    if player:GetMapId() == s.map and player:GetDistance(s.x, s.y, s.z) < 10 then
        print(string.format("[718] ERROR: the spot before Sargobras reads as area %d, not %d; the gate cannot hold here", player:GetAreaId(), ACHERUS_AREA))
        return
    end
    player:Teleport(s.map, s.x, s.y, s.z, s.o)
    player:SendBroadcastMessage("Sargobras says: Not so fast. The living will want to know who you were. Come and tell me.")
end

local function candidates(player)
    local q = CharDBQuery("SELECT guid, name, level FROM characters WHERE account = " .. player:GetAccountId()
        .. " AND level >= " .. SOUL_MIN_LEVEL .. " AND class <> " .. CLASS_DEATH_KNIGHT
        .. " AND guid <> " .. player:GetGUIDLow() .. " AND deleteInfos_Account IS NULL ORDER BY level DESC, name")
    local out = {}
    if q then
        repeat
            out[#out + 1] = { guid = q:GetUInt32(0), name = q:GetString(1), level = q:GetUInt32(2) }
        until not q:NextRow()
    end
    return out
end

local APPRENTICE_TO_ARTISAN = {
    [2259]  = { 171, 11611 },
    [2018]  = { 164, 9785  },
    [7411]  = { 333, 13920 },
    [4036]  = { 202, 12656 },
    [45357] = { 773, 45360 },
    [25229] = { 755, 28895 },
    [2108]  = { 165, 10662 },
    [3908]  = { 197, 12180 },
    [2366]  = { 182, 11993 },
    [2575]  = { 186, 10248 },
    [8613]  = { 393, 10768 },
}
local MAXED_AT_TRAINING = 2
local carrying = {}

local function on_learn_spell(event, player, spell)
    local prof = APPRENTICE_TO_ARTISAN[spell]
    if not prof or player:GetClass() ~= CLASS_DEATH_KNIGHT then return end
    local guid = player:GetGUIDLow()
    if carrying[guid] then return end
    local q = CharDBQuery("SELECT COUNT(*) FROM basic_718_maxed WHERE dk = " .. guid)
    if q and q:GetUInt32(0) >= MAXED_AT_TRAINING then return end
    player:LearnSpell(prof[2])
    player:SetSkill(prof[1], 4, 300, 300)
    CharDBExecute(string.format("INSERT IGNORE INTO basic_718_maxed (dk, skill) VALUES (%d, %d)", guid, prof[1]))
    player:SendBroadcastMessage("What you learned in life comes back to you at once.")
end

local function carry_professions(player, soul_guid)
    carrying[player:GetGUIDLow()] = true
    local learned, skills = 0, 0
    local q = CharDBQuery("SELECT spell FROM character_spell WHERE guid = " .. soul_guid)
    if q then
        repeat
            local spell = q:GetUInt32(0)
            if DATA.profession_spells[spell] and not player:HasSpell(spell) then
                player:LearnSpell(spell)
                learned = learned + 1
            end
        until not q:NextRow()
    end
    q = CharDBQuery("SELECT skill, value, max FROM character_skills WHERE guid = " .. soul_guid)
    if q then
        repeat
            local skill, value, max = q:GetUInt32(0), q:GetUInt32(1), q:GetUInt32(2)
            if DATA.professions[skill] then
                player:SetSkill(skill, math.max(1, math.ceil(max / 75)), value, max)
                skills = skills + 1
            end
        until not q:NextRow()
    end
    carrying[player:GetGUIDLow()] = nil
    return learned, skills
end

local COMMAND_SETTLE_MS = 1000
local trading = {}

local function give_soul(player, soul_guid, done)
    local dk_guid, dk_name, account = player:GetGUIDLow(), player:GetName(), player:GetAccountId()
    local guid = player:GetGUID()
    if trading[dk_guid] then
        player:SendBroadcastMessage("Sargobras says: Patience. I'm already at work.")
        return
    end
    local soul
    for _, c in ipairs(candidates(player)) do if c.guid == soul_guid then soul = c end end
    if not soul then
        player:SendBroadcastMessage("Sargobras says: That one isn't yours to give, or isn't ready.")
        return
    end
    trading[dk_guid] = true
    local learned, skills = carry_professions(player, soul.guid)

    local function stop(step, why)
        trading[dk_guid] = nil
        print(string.format("[death-knight-souls] ERROR: %s's trade of %s stopped at %s: %s. Done before it: %d profession skills"
            .. " and %d recipes carried; the ledger still says owed. To debug: run the step's command at the console and read its answer.",
            dk_name, soul.name, step, why, skills, learned))
        local p = GetPlayerByGUID(guid)
        if p then p:SendBroadcastMessage("Sargobras says: The soul slipped through my fingers. Try again in a moment. (The server log says why.)") end
    end

    local function finish(holding_id)
        CharDBExecute("UPDATE basic_718_souls SET soul = " .. soul.guid .. ", soul_account = " .. account .. ", holding_account = " .. holding_id
            .. ", state = " .. STATE_GIVEN .. ", changed = UNIX_TIMESTAMP() WHERE dk = " .. dk_guid)
        trading[dk_guid] = nil
        local p = GetPlayerByGUID(guid)
        if not p then return end
        hold_selection(p, false)
        p:SendBroadcastMessage(string.format("Sargobras says: %s, for the Lich King. You, for the living. Off you go. "
            .. "(%d profession skills and %d recipes carried over.)", soul.name, skills, learned))
        if done then done(p) end
    end

    local function move(holding_id, holding_name)
        RunCommand(".character changeaccount " .. holding_name .. " " .. soul.name)
        CreateLuaEvent(function()
            local check = CharDBQuery("SELECT account FROM characters WHERE guid = " .. soul.guid)
            if not check then return stop("the move", soul.name .. " is no longer in the characters table") end
            if check:GetUInt32(0) ~= holding_id then
                return stop("the move", string.format("%s is still on account %d, not %s (%d); is that account full (10 characters)?",
                    soul.name, check:GetUInt32(0), holding_name, holding_id))
            end
            finish(holding_id)
        end, COMMAND_SETTLE_MS, 1)
    end

    local name = HOLDING_PREFIX .. account
    local q = AuthDBQuery("SELECT id FROM account WHERE username = '" .. name .. "'")
    if q then return move(q:GetUInt32(0), name) end
    local chars = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local pw = {}
    for i = 1, 16 do local k = math.random(#chars); pw[i] = chars:sub(k, k) end
    RunCommand(".account create " .. name .. " " .. table.concat(pw))
    CreateLuaEvent(function()
        local made = AuthDBQuery("SELECT id FROM account WHERE username = '" .. name .. "'")
        if not made then return stop("making the holding account", "no account named " .. name .. " after .account create") end
        move(made:GetUInt32(0), name)
    end, COMMAND_SETTLE_MS, 1)
end

local function death_knight_look(race, gender, dk_race, dk_gender, dk_skin, dk_face)
    if race == dk_race and gender == dk_gender then return dk_skin, dk_face end
    local by_race = DATA.death_knight_looks[race]
    local looks = by_race and by_race[gender]
    if not looks or #looks == 0 then return nil end
    local look = looks[math.random(#looks)]
    return look.skin, look.faces[math.random(#look.faces)]
end

local function take_back(player, row)
    local dk_guid, dk_name = player:GetGUIDLow(), player:GetName()
    local me = CharDBQuery("SELECT race, gender, skin, face FROM characters WHERE guid = " .. dk_guid)
    local soul = CharDBQuery("SELECT name, race, gender FROM characters WHERE guid = " .. row.soul)
    local home = AuthDBQuery("SELECT username FROM account WHERE id = " .. row.soul_account)
    if not me or not soul or not home then
        print("[death-knight-souls] ERROR: cannot return the soul of " .. dk_name .. " (death knight, soul or home account row missing)")
        player:SendBroadcastMessage("Sargobras says: I can't find that soul. (The server log says why.)")
        return
    end
    local soul_name, race, gender = soul:GetString(0), soul:GetUInt32(1), soul:GetUInt32(2)
    local skin, face = death_knight_look(race, gender, me:GetUInt32(0), me:GetUInt32(1), me:GetUInt32(2), me:GetUInt32(3))
    local home_name = home:GetString(0)
    CharDBExecute("UPDATE basic_718_souls SET state = " .. STATE_RETURNING .. ", changed = UNIX_TIMESTAMP() WHERE dk = " .. dk_guid)
    player:SendBroadcastMessage("Sargobras says: As you wish. " .. soul_name .. " walks again. Mostly.")
    CreateLuaEvent(function()
        RunCommand(".character erase " .. dk_name)
        RunCommand(".account delete BUDDY" .. dk_guid)
        CharDBExecute("DELETE FROM buddy_roster WHERE owner = " .. dk_guid)
        CharDBExecute("DELETE FROM buddy_clan WHERE owner = " .. dk_guid)
    end, 1000, 1)
    CreateLuaEvent(function()
        RunCommand(".character changeaccount " .. home_name .. " " .. soul_name)
        if skin then
            CharDBExecute("UPDATE characters SET skin = " .. skin .. ", face = " .. face .. " WHERE guid = " .. row.soul)
        end
        CharDBExecute("DELETE FROM basic_718_souls WHERE dk = " .. dk_guid)
    end, 1000 + RETURN_DELAY_MS, 1)
end

local skip_wanted = {}

local function give_buddies(p)
    if BuddiesGiveDeathKnightBuddies then BuddiesGiveDeathKnightBuddies(p)
    else print("[death-knight-souls] ERROR: sargobras.lua isn't loaded; " .. p:GetName() .. " got no buddies (its next login gives them)") end
end

local function rise(player)
    local guid, map_id = player:GetGUID(), player:GetMapId()
    local bx, by, bz, bo = player:GetX(), player:GetY(), player:GetZ(), player:GetO()
    local theta = math.random() * 2 * math.pi
    local sx    = bx + math.cos(theta) * RISER_DISTANCE
    local sy    = by + math.sin(theta) * RISER_DISTANCE
    local sz    = bz
    local face  = math.atan2(by - sy, bx - sx) % (2 * math.pi)
    local riser, marker

    local function at(ms, fn)
        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if p then fn(p) end
        end, ms, 1)
    end
    local function find(p, g) return g and p:GetMap():GetWorldObject(g) end

    at(RISE_AT.appear, function(p)
        local c = p:SpawnCreature(RISER, sx, sy, sz, face, TEMPSUMMON_TIMED_DESPAWN, RISE_AT.gone - RISE_AT.appear + 2000)
        if not c then
            print("[death-knight-souls] ERROR: the rise for " .. p:GetName() .. ": Sargobras (creature " .. RISER
                .. ") could not be summoned; the circle and the raise still follow. To debug: is install step E040 applied?")
            return
        end
        riser = c:GetGUID()
    end)
    at(RISE_AT.point, function(p)
        local c = find(p, riser)
        if c then c:SetFacing(face); c:EmoteState(EMOTE_STATE_POINT) end
    end)
    at(RISE_AT.freeze, function(p)
        local c = find(p, riser)
        if c then c:AddAura(FREEZE_SPELL, c) end
    end)
    at(RISE_AT.circle, function(p)
        local m = p:SpawnCreature(CIRCLE_MARKER, bx, by, bz, 0, TEMPSUMMON_TIMED_DESPAWN, RISE_AT.gone - RISE_AT.circle + 2000)
        if not m or not m:AddAura(CIRCLE_SPELL, m) then
            print("[death-knight-souls] ERROR: the rise for " .. p:GetName() .. ": no red circle (marker "
                .. CIRCLE_MARKER .. (m and " stands, but spell " .. CIRCLE_SPELL .. " didn't take" or " could not be summoned") .. ")")
        end
        if m then marker = m:GetGUID() end
    end)
    at(RISE_AT.raise, function(p)
        local released = p:GetDistance(bx, by, bz) > 5
        if p:IsDead() then p:ResurrectPlayer(1.0, false) end
        if released then p:Teleport(map_id, bx, by, bz, bo) end
        local c = find(p, riser)
        if c then
            c:RemoveAura(FREEZE_SPELL)
            c:EmoteState(0)
            c:CastSpell(p, RISE_SPELL, true)
            c:CastSpell(c, RISE_SPELL, true)
            c:SendUnitSay("Up. The living are waiting.", 0)
        else
            p:CastSpell(p, RISE_SPELL, true)
        end
        give_buddies(p)
    end)
    at(RISE_AT.gone, function(p)
        local c, m = find(p, riser), find(p, marker)
        if c then c:DespawnOrUnsummon(0) end
        if m then m:DespawnOrUnsummon(0) end
    end)
end

local function watch_the_fall(player)
    local guid, name, waited = player:GetGUID(), player:GetName(), 0
    local function look()
        local p = GetPlayerByGUID(guid)
        waited = waited + RISE_WATCH_MS
        if not p then
            if waited < RISE_WATCH_FOR_MS then CreateLuaEvent(look, RISE_WATCH_MS, 1) end
            return
        end
        if p:IsDead() then return rise(p) end
        if waited >= RISE_WATCH_FOR_MS then
            print(string.format("[death-knight-souls] ERROR: %s skipped the story and was still alive %d s after the fall"
                .. " began (map %d at %.1f, %.1f, %.1f); no rise played, buddies given. To debug: did the Ebon Hold's floor"
                .. " hold this time (issue 718's open question)?", name, RISE_WATCH_FOR_MS / 1000, p:GetMapId(), p:GetX(), p:GetY(), p:GetZ()))
            p:SendBroadcastMessage("Sargobras says: On your feet already? Then you never needed me.")
            give_buddies(p)
            return
        end
        CreateLuaEvent(look, RISE_WATCH_MS, 1)
    end
    CreateLuaEvent(look, RISE_WATCH_MS, 1)
end

local DK_STORY = dofile(script_dir() .. "data/death-knight-skip-quests.lua")
local STORY_ITEMS = {}
do
    local ids = {}
    for _, q in ipairs(DK_STORY) do ids[#ids + 1] = q[1] end
    local q = WorldDBQuery("SELECT RewardItem1, RewardItem2, RewardItem3, RewardItem4, RewardChoiceItemID1, RewardChoiceItemID2,"
        .. " RewardChoiceItemID3, RewardChoiceItemID4, RewardChoiceItemID5, RewardChoiceItemID6, StartItem"
        .. " FROM quest_template WHERE ID IN (" .. table.concat(ids, ",") .. ")")
    if q then
        repeat
            for c = 0, 10 do local e = q:GetUInt32(c) if e ~= 0 then STORY_ITEMS[e] = true end end
        until not q:NextRow()
    end
end
local PLAYER_FLAGS_FIELD     = 150
local PLAYER_FLAG_NO_XP_GAIN = 0x02000000

local function tell_the_story(player)
    local had_flag = player:HasFlag(PLAYER_FLAGS_FIELD, PLAYER_FLAG_NO_XP_GAIN)
    local money    = player:GetCoinage()
    local before   = {}
    for e in pairs(STORY_ITEMS) do before[e] = player:GetItemCount(e) end
    if not had_flag then player:SetPlayerFlag(PLAYER_FLAG_NO_XP_GAIN) end

    local mask, done, already, failed = player:GetRaceMask(), 0, 0, {}
    for _, q in ipairs(DK_STORY) do
        local quest, races = q[1], q[2]
        if races == 0 or bit.band(races, mask) ~= 0 then
            if player:GetQuestRewardStatus(quest) then
                already = already + 1
            else
                player:AddQuest(quest)
                player:CompleteQuest(quest)
                player:RewardQuest(quest)
                if player:GetQuestRewardStatus(quest) then done = done + 1 else failed[#failed + 1] = tostring(quest) end
                for e in pairs(STORY_ITEMS) do
                    local extra = player:GetItemCount(e) - before[e]
                    if extra > 0 then player:RemoveItem(e, extra) end
                end
            end
        end
    end

    if not had_flag then player:RemovePlayerFlag(PLAYER_FLAG_NO_XP_GAIN) end
    player:SetCoinage(money)
    return done, already, failed
end

local function skip_story(player)
    local done, already, failed = tell_the_story(player)
    local line = string.format("Sargobras says: Your story is told: %d quests, %d already were. Keep what it taught you; the rest stays here.", done, already)
    if #failed > 0 then
        line = line .. " These would not go through: " .. table.concat(failed, ", ") .. " (a game master can finish them by hand)."
        print(string.format("[death-knight-souls] ERROR: skipping the story for %s: %d rewarded, %d already, refused: %s"
            .. " (to debug: quest log full? the quest's starting item refused? check each with .quest add / .quest complete)",
            player:GetName(), done, already, table.concat(failed, ", ")))
    end
    player:SendBroadcastMessage(line)
    if player:HasItem(RUNEBLADE, 1, true) then
        player:SendBroadcastMessage("Sargobras says: You already carry your runeblade. I give nothing twice.")
    elseif not player:AddItem(RUNEBLADE, 1) then
        print("[death-knight-souls] ERROR: " .. player:GetName() .. " skipped the story but the Runed Soulblade ("
            .. RUNEBLADE .. ") would not go in the bags (full?); done before it: the trade and the story. Give it by hand: .additem " .. RUNEBLADE)
        player:SendBroadcastMessage("Sargobras says: Your bags are full, so your runeblade stays with me. (The server log says why.)")
    end
    CharDBExecute("UPDATE basic_718_souls SET skipped = 1 WHERE dk = " .. player:GetGUIDLow())
    local a, r = math.random() * 2 * math.pi, SKIP_SCATTER * math.sqrt(math.random())
    local s    = SKIP_LANDING
    player:SendBroadcastMessage("Sargobras says: The living are below. Mind the first step.")
    player:Teleport(s.map, s.x + math.cos(a) * r, s.y + math.sin(a) * r, s.z, s.o)
    watch_the_fall(player)
end

local function on_hello(event, player, creature)
    player:GossipClearMenu()
    local row = player:GetClass() == CLASS_DEATH_KNIGHT and ledger(player:GetGUIDLow()) or nil
    if row and row.state == STATE_OWED then
        if not player:IsInGuild() then
            player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "First, our clan needs a name.", 0, INTID_CLAN)
        else
            local skip = skip_wanted[player:GetGUIDLow()]
            if not skip then
                player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "I'd rather skip the story.", 0, INTID_SKIP)
            else
                player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "I changed my mind, I want to follow the Lich King for a time.", 0, INTID_UNSKIP)
            end
            for _, c in ipairs(candidates(player)) do
                local confirm = string.format("Give %s to the Lich King? %s leaves your character list; you can ask for them back here later.%s",
                    c.name, c.name, skip and " Your story in Acherus will be told for you, and you will stand at the Ebon Hold." or "")
                player:GossipMenuAddItem(GOSSIP_ICON_CHAT, string.format("Give %s (level %d) to the Lich King%s.", c.name, c.level,
                    skip and ", and skip the story" or ""), 0, c.guid, false, confirm)
            end
        end
        player:GossipSendMenu(TEXT_OWED, creature)
    elseif row and row.state == STATE_GIVEN then
        if intro_done(player, row) then
            player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "I want my old life back.", 0, INTID_RETURN, false,
                "This death knight will be erased for good, and your old self returns to your character list, undead-pale. Are you sure?")
        end
        if not player:IsInGuild() then
            player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "Let me name our clan.", 0, INTID_CLAN)
        end
        player:GossipSendMenu(TEXT_GIVEN, creature)
    else
        player:GossipSendMenu(TEXT_OTHER, creature)
    end
end

local function on_select(event, player, creature, sender, intid, code)
    player:GossipComplete()
    local row = player:GetClass() == CLASS_DEATH_KNIGHT and ledger(player:GetGUIDLow()) or nil
    if not row then return end
    if row.state == STATE_GIVEN and intid == INTID_RETURN then
        if intro_done(player, row) then take_back(player, row) end
    elseif intid == INTID_CLAN then
        if not player:IsInGuild() then BuddiesListenForClanName(player, creature) end
    elseif row.state == STATE_OWED and intid == INTID_SKIP then
        skip_wanted[player:GetGUIDLow()] = true
        on_hello(event, player, creature)
    elseif row.state == STATE_OWED and intid == INTID_UNSKIP then
        skip_wanted[player:GetGUIDLow()] = nil
        on_hello(event, player, creature)
    elseif row.state == STATE_OWED and intid ~= INTID_RETURN then
        if not player:IsInGuild() then return end
        give_soul(player, intid, function(p)
            local here = p:GetNearestCreature(30, SARGOBRAS)
            if here then vanish(here, p) else hide_from(p) end
            if skip_wanted[p:GetGUIDLow()] then
                skip_wanted[p:GetGUIDLow()] = nil
                p:RegisterEvent(function(_, _, _, pp) skip_story(pp) end, SKIP_AFTER_MS, 1)
            else
                give_buddies(p)
            end
        end)
    end
end

local function on_lich_king_hello(event, player, creature)
    if player:GetClass() ~= CLASS_DEATH_KNIGHT then return false end
    local row = ledger(player:GetGUIDLow())
    if not row or row.state ~= STATE_OWED then return false end
    creature:SendUnitWhisper("You still carry a life that is not mine. Settle it with Sargobras, and then I will have work for you.", 0, player)
    player:GossipComplete()
    return true
end

local function on_first_login(event, player)
    if player:GetClass() ~= CLASS_DEATH_KNIGHT then return end
    if CharDBQuery("SELECT 1 FROM buddy_roster WHERE buddy = " .. player:GetGUIDLow()) then return end
    CharDBExecute("INSERT IGNORE INTO basic_718_souls (dk, state, changed) VALUES (" .. player:GetGUIDLow() .. ", " .. STATE_OWED .. ", UNIX_TIMESTAMP())")
    hold_selection(player, true)
end

local function on_login(event, player)
    check_gate(player, player:GetAreaId())
    if player:GetClass() ~= CLASS_DEATH_KNIGHT then return end
    local row = ledger(player:GetGUIDLow())
    if row and row.state == STATE_OWED then hold_selection(player, true)
    elseif row and row.state == STATE_GIVEN then hide_from(player) end
end

if not CharDBQuery("SHOW COLUMNS FROM basic_718_souls LIKE 'skipped'") then
    print("[death-knight-souls] ERROR: basic_718_souls has no skipped column (install step E041 not re-applied since"
        .. " 2026-10-12?); death knight souls are OFF: no gate, no Sargobras menu. To fix: apply"
        .. " sql/basic/db_characters.src/03-death-knight-souls.apply.sql, then .reload ale")
    return
end

RegisterPlayerEvent(PLAYER_EVENT_ON_FIRST_LOGIN, on_first_login)
RegisterPlayerEvent(PLAYER_EVENT_ON_LEARN_SPELL, on_learn_spell)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, on_login)
RegisterPlayerEvent(PLAYER_EVENT_ON_UPDATE_ZONE, function(event, player, new_zone, new_area) check_gate(player, new_area) end)
RegisterPlayerEvent(PLAYER_EVENT_ON_UPDATE_AREA, function(event, player, old_area, new_area) check_gate(player, new_area) end)
RegisterCreatureGossipEvent(LICH_KING, GOSSIP_EVENT_ON_HELLO, on_lich_king_hello)
RegisterCreatureGossipEvent(SARGOBRAS, GOSSIP_EVENT_ON_HELLO,  on_hello)
RegisterCreatureGossipEvent(SARGOBRAS, GOSSIP_EVENT_ON_SELECT, on_select)
