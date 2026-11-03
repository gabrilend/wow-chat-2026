
#include "buddies.h"
#include "buddies_army.h"
#include "buddies_roam.h"
#include "buddies_stand_ins_pick.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "Random.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <cmath>
#include <map>

using namespace Acore::ChatCommands;

static constexpr uint32 ARMY_SIZE      = 64;
static constexpr uint32 ARMY_MOST      = 200;
static constexpr uint32 PASS_MS        = 2000;
static constexpr uint32 BRING_PER_PASS = 4;
static constexpr uint64 NOTE_MS        = 30000;
static constexpr float  SPREAD         = 8.0f;

struct Army
{
    uint32 size = ARMY_SIZE;
    std::vector<uint32> standIns;
    uint64 lastNote = 0;
    uint32 brought = 0, displaced = 0;
};
static std::map<uint32, Army> sArmies;

std::vector<std::pair<uint32, uint32>> BuddyArmyPairs()
{
    std::vector<std::pair<uint32, uint32>> pairs;
    for (auto const& [gm, army] : sArmies)
        for (uint32 s : army.standIns)
            pairs.emplace_back(s, gm);
    return pairs;
}

static bool TestRealm() { return sConfigMgr->GetOption<bool>("Buddies.TestRealm", false); }

static uint32 OwnInWorld(uint32 gm)
{
    std::vector<uint32> ours;
    auto it = sArmies.find(gm);
    if (it != sArmies.end())
        ours = it->second.standIns;
    uint32 n = 0;
    for (auto const& [buddy, owner] : BuddyRosterPairs())
        if (owner == gm && std::find(ours.begin(), ours.end(), buddy) == ours.end())
            if (Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddy)))
                if (b->IsInWorld())
                    ++n;
    return n;
}

static void Keep(uint32 gmGuid, Army& army, uint64 now)
{
    Player* gm = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(gmGuid));
    if (!gm || !gm->IsInWorld())
    {
        for (uint32 s : army.standIns)
            BuddyDismissStandIn(s);
        LOG_INFO("module", "mod-buddies: army of {}: the game master left; {} stand-ins sent out", gmGuid, army.standIns.size());
        army.standIns.clear();
        army.size = 0;
        return;
    }

    army.standIns.erase(std::remove_if(army.standIns.begin(), army.standIns.end(), [](uint32 s) {
        return !BuddyStandInOnItsWay(s) && !ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(s));
    }), army.standIns.end());

    uint32 own  = OwnInWorld(gmGuid);
    uint32 room = army.size > own ? army.size - own : 0;
    while (army.standIns.size() > room)
    {
        BuddyDismissStandIn(army.standIns.back());
        army.standIns.pop_back();
        ++army.displaced;
    }
    for (uint32 k = 0; k < BRING_PER_PASS && army.standIns.size() < room; ++k)
    {
        uint8  role  = BuddyStandIn::ANY_ROLE;
        float  a = float(rand_norm()) * 6.2831853f, r = float(rand_norm()) * SPREAD;
        std::string said;
        uint32 s = BuddyBringStandIn(gm->GetTeamId() == TEAM_HORDE ? 1 : 0, role, gm->GetLevel(), 0, 0, gm->GetMapId(),
            gm->GetPositionX() + std::cos(a) * r, gm->GetPositionY() + std::sin(a) * r, gm->GetPositionZ(), gm->GetOrientation(), said);
        if (!s)
        {
            if (now - army.lastNote > NOTE_MS)
            {
                army.lastNote = now;
                ChatHandler(gm->GetSession()).PSendSysMessage("Army: a stand-in could not be brought ({}); {} of {} so far, trying again.",
                    said, army.standIns.size() + own, army.size);
            }
            LOG_ERROR("module", "mod-buddies: army of {}: {}", gm->GetName(), said);
            break;
        }
        army.standIns.push_back(s);
        ++army.brought;
    }

    for (uint32 s : army.standIns)
    {
        if (BuddyStandInOnItsWay(s))
            continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(s));
        PlayerbotAI* ai = bot ? GET_PLAYERBOT_AI(bot) : nullptr;
        if (!bot || !bot->IsInWorld() || !ai)
            continue;
        if (ai->GetMaster() != gm)
            ai->SetMaster(gm);
        if (bot->GetMapId() != gm->GetMapId() && !bot->IsBeingTeleported())
            bot->TeleportTo(gm->GetMapId(), gm->GetPositionX(), gm->GetPositionY(), gm->GetPositionZ(), gm->GetOrientation());
    }
}

class buddies_army_world : public WorldScript
{
public:
    buddies_army_world() : WorldScript("buddies_army_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        _sinceLast += diff;
        if (_sinceLast < PASS_MS || sArmies.empty() || !BuddiesEnabled())
            return;
        _sinceLast = 0;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        for (auto it = sArmies.begin(); it != sArmies.end(); )
        {
            Keep(it->first, it->second, now);
            it = it->second.size == 0 ? sArmies.erase(it) : std::next(it);
        }
    }

private:
    uint32 _sinceLast = 0;
};

class buddies_army_command : public CommandScript
{
public:
    buddies_army_command() : CommandScript("buddies_army_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy army", HandleArmy, SEC_GAMEMASTER, Console::No },
        };
        return commandTable;
    }

    static bool HandleArmy(ChatHandler* handler, Optional<std::string> word)
    {
        if (!TestRealm())
        {
            handler->PSendSysMessage("The army is for a test realm only: a realm branch (scripts/branch-realm SOURCE NAME, "
                "then scripts/worldserver --profile NAME), whose launcher sets Buddies.TestRealm. This realm is not one.");
            return true;
        }
        Player* gm = handler->GetPlayer();
        uint32 me = gm->GetGUID().GetCounter();
        auto it = sArmies.find(me);

        if (word && *word == "dismiss")
        {
            if (it == sArmies.end())
            {
                handler->PSendSysMessage("You have no army up.");
                return true;
            }
            for (uint32 s : it->second.standIns)
                BuddyDismissStandIn(s);
            handler->PSendSysMessage("Army dismissed: {} stand-ins sent out (kept for the next asker); your own buddies stay.",
                it->second.standIns.size());
            sArmies.erase(it);
            return true;
        }

        uint32 size = ARMY_SIZE;
        if (word)
        {
            char* end = nullptr;
            unsigned long n = std::strtoul(word->c_str(), &end, 10);
            if (!end || *end || n < 1 || n > ARMY_MOST)
            {
                handler->PSendSysMessage("'{}' is not an army size: give a number from 1 to {}, or 'dismiss'.", *word, ARMY_MOST);
                return true;
            }
            size = uint32(n);
        }
        else if (it != sArmies.end())
        {
            Army const& a = it->second;
            uint32 own = OwnInWorld(me), inWorld = 0, onWay = 0, mastered = 0;
            for (uint32 s : a.standIns)
            {
                if (BuddyStandInOnItsWay(s)) { ++onWay; continue; }
                if (Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(s)))
                {
                    ++inWorld;
                    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(b))
                        if (ai->GetMaster() == gm)
                            ++mastered;
                }
            }
            handler->PSendSysMessage("Army of {}: {} of your own buddies, {} stand-ins in the world ({} following you), {} on their way; "
                "{} brought and {} displaced since it was raised.", a.size, own, inWorld, mastered, onWay, a.brought, a.displaced);
            return true;
        }

        Army& a = sArmies[me];
        a.size = size;
        uint32 own = OwnInWorld(me);
        handler->PSendSysMessage("Army of {}: {} of your own buddies, {} stand-ins to come ({} every {} seconds), {} already here. "
            "They roam where you are, as your buddies; \".buddy path <way>\" picks how they find their way.",
            size, own, size > own + a.standIns.size() ? size - own - a.standIns.size() : 0, BRING_PER_PASS, PASS_MS / 1000, a.standIns.size());
        return true;
    }
};

void AddSC_buddies_army()
{
    new buddies_army_world();
    new buddies_army_command();
}
