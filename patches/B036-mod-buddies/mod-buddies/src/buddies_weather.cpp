
#include "buddies_weather_deck.h"
#include "buddies_weather_storm.h"
#include "buddies_av_valley_data.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "MiscPackets.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <cmath>
#include <map>
#include <random>
#include <string>

using namespace Acore::ChatCommands;

namespace
{
    constexpr uint32 AV_MAP     = 30;
    constexpr uint32 AV_ZONE    = 2597;
    constexpr uint32 PASS_MS    = 5000;
    constexpr float  GRADE_STEP = 0.05f;

    uint64 sSeed  = 0;
    uint64 sStart = 0;
    BuddyWeather::Sky SkyNow()
    {
        uint64 now = GameTime::GetGameTimeMS().count();
        if (sStart == 0)
        {
            std::random_device rd;
            sSeed  = (uint64(rd()) << 32) ^ uint64(rd());
            sStart = now;
        }
        return BuddyWeather::At(sSeed, now - sStart);
    }
    bool On() { return sConfigMgr->GetOption<int32>("Buddies.AlteracWeather", 0) == 1; }

    class buddies_weather_world : public WorldScript
    {
    public:
        buddies_weather_world() : WorldScript("buddies_weather_world") { }

        void OnUpdate(uint32 diff) override
        {
            _since += diff;
            if (_since < PASS_MS)
                return;
            _since = 0;
            if (!On())
            {
                _given.clear();
                _underStorm.clear();
                return;
            }
            BuddyWeather::Sky sky = SkyNow();
            if (!_stormReady)
            {
                _valley = BuddyStorm::ValleyFromCells(AV_VALLEY_CELLS, sizeof(AV_VALLEY_CELLS) / sizeof(AV_VALLEY_CELLS[0]));
                _storm = BuddyStorm::Start(_valley);
                _stormRng.seed(uint32(sSeed));
                _stormReady = true;
            }
            for (uint32 sec = 0; sec < PASS_MS / 1000; ++sec)
                BuddyStorm::Step(_storm, _valley, _stormRng);
            sMapMgr->DoForAllMapsWithMapId(AV_MAP, [&](Map* map)
            {
                auto found = _given.find(map->GetInstanceId());
                if (found == _given.end())
                    found = _given.emplace(map->GetInstanceId(), std::make_pair(uint32(0), -1.0f)).first;
                auto& was = found->second;
                bool skyGiven = !(was.first == sky.state && std::abs(was.second - sky.grade) < GRADE_STEP && was.second >= 0.0f);
                if (skyGiven)
                {
                    map->SetZoneWeather(AV_ZONE, WeatherState(sky.state), sky.grade);
                    was = { sky.state, sky.grade };
                }

                map->DoForAllPlayers([&](Player* player)
                {
                    float d = std::hypot(player->GetPositionX() - _storm.x, player->GetPositionY() - _storm.y);
                    auto reach = BuddyStorm::Reach(d);
                    auto& last = _underStorm[player->GetGUID().GetCounter()];
                    if (reach.first != 0)
                    {
                        if (skyGiven || last.first != reach.first || std::abs(last.second - reach.second) >= GRADE_STEP)
                        {
                            player->SendDirectMessage(WorldPackets::Misc::Weather(WeatherState(reach.first), reach.second).Write());
                            last = reach;
                        }
                    }
                    else if (last.first != 0)
                    {
                        player->SendDirectMessage(WorldPackets::Misc::Weather(WeatherState(sky.state), sky.grade).Write());
                        last = { 0, 0.0f };
                    }
                });
            });
        }

    private:
        uint32 _since = 0;
        std::map<uint32, std::pair<uint32, float>> _given;
        bool                _stormReady = false;
        BuddyStorm::Valley  _valley;
        BuddyStorm::Storm   _storm;
        std::mt19937        _stormRng;
        std::map<uint32, std::pair<uint32, float>> _underStorm;
    };

    class buddies_weather_command : public CommandScript
    {
    public:
        buddies_weather_command() : CommandScript("buddies_weather_command") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable commandTable =
            {
                { "buddy weather", HandleWeather, SEC_GAMEMASTER, Console::Yes },
            };
            return commandTable;
        }

        static bool HandleWeather(ChatHandler* handler)
        {
            BuddyWeather::Sky sky = SkyNow();
            uint64 ms = GameTime::GetGameTimeMS().count() - sStart;
            uint64 turn = ms / BuddyWeather::TURN_MS;
            auto deck = BuddyWeather::Deck(sSeed, turn / BuddyWeather::KIND_COUNT);
            std::string rest;
            for (uint64 k = turn % BuddyWeather::KIND_COUNT + 1; k < BuddyWeather::KIND_COUNT; ++k)
                rest += std::string(rest.empty() ? "" : ", ") + BuddyWeather::KIND_NAMES[deck[size_t(k)]];
            handler->PSendSysMessage("Alterac Valley's sky ({}): {} at {}% strength, {} s into its turn; the rest of this deck: {}.",
                On() ? "shared, Buddies.AlteracWeather on" : "off: each match has its own",
                BuddyWeather::KIND_NAMES[sky.kind], uint32(sky.strength * 100.0f),
                uint32((ms % BuddyWeather::TURN_MS) / 1000), rest.empty() ? "none, a new deck next" : rest);
            return true;
        }
    };
}

void AddSC_buddies_weather()
{
    new buddies_weather_world();
    new buddies_weather_command();
}
