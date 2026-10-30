/*
 * buddies_weather.cpp - every Alterac Valley on the server under one sky
 * (issue 921, 921a).
 *
 * For a general audience: each Alterac Valley match is its own copy of the
 * map, and the server gives each copy its own weather. With the switch on,
 * this sets the same sky on every copy, from the shuffled deck of weathers
 * (buddies_weather_deck.h), worked out from a seed drawn when the server
 * starts and the time since. Every few seconds each copy is given the sky
 * of that moment if it changed; a player arriving gets it from the copy, as
 * the game does for any weather. ".buddy weather" says the sky now and what
 * the deck holds.
 *
 * Switch: Buddies.AlteracWeather (0 off, the default; 1 on), read each pass.
 * The wandering storm (921b): one storm for the server, moved a second's
 * walk for every second, in the valley's cells (buddies_av_valley_data.h,
 * generated from the battleground's own places); each player in a copy is
 * sent the storm's weather by their distance from it (the downpour within
 * 60 yards, thinning to 90), and the shared sky again once out of reach.
 */

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
    // {{{ the numbers
    // AV_MAP, AV_ZONE: Alterac Valley's map and zone (the client's area
    //                  table: zone 2597 on map 30).
    // PASS_MS:         how often every copy is given the sky of the moment.
    // GRADE_STEP:      a change of strength smaller than this isn't sent (the
    //                  client fades weather itself; a packet a pass is waste).
    constexpr uint32 AV_MAP     = 30;
    constexpr uint32 AV_ZONE    = 2597;
    constexpr uint32 PASS_MS    = 5000;
    constexpr float  GRADE_STEP = 0.05f;
    // }}}

    // {{{ the server's sky
    // The seed, drawn from the system's own randomness the first time it is
    // needed (so no two server runs deal alike), and the moment it was drawn.
    uint64 sSeed  = 0;
    uint64 sStart = 0;
    // {{{ local function SkyNow()
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
    // }}}
    bool On() { return sConfigMgr->GetOption<int32>("Buddies.AlteracWeather", 0) == 1; }
    // }}}

    // {{{ buddies_weather_world
    // Every PASS_MS, while the switch is on: each copy of the valley is given
    // the sky of the moment when its weather or strength has moved on since
    // it was last given one. A copy is remembered by its instance id; the
    // memory is cleared when the switch goes off, so turning it on again
    // sets every copy afresh.
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
            // the storm: a step for every second since the last pass
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
                // the shared sky first: given to the copy when it has moved
                // on. Given, it reaches every player in the zone, those under
                // the storm too, so they are sent the storm again below.
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

                // each player: the storm's weather by distance, sent when it
                // changes (or the sky was just given over it); out of reach
                // after being under it, the shared sky again
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
        std::map<uint32, std::pair<uint32, float>> _given;   // instance id -> (state, grade) last given; grade -1: never
        bool                _stormReady = false;
        BuddyStorm::Valley  _valley;
        BuddyStorm::Storm   _storm;
        std::mt19937        _stormRng;
        std::map<uint32, std::pair<uint32, float>> _underStorm;   // player guid -> the storm weather last sent (0: none)
    };
    // }}}

    // {{{ .buddy weather
    // The sky now and the rest of this deck, for game masters.
    class buddies_weather_command : public CommandScript
    {
    public:
        buddies_weather_command() : CommandScript("buddies_weather_command") { }

        ChatCommandTable GetCommands() const override
        {
            // multi-word names join the ".buddy" table the beds file starts
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
    // }}}
}

// {{{ AddSC_buddies_weather
void AddSC_buddies_weather()
{
    new buddies_weather_world();
    new buddies_weather_command();
}
// }}}
