
#include "buddies_talents.h"
#include "buddies_roam.h"
#include "buddies_talent_draw.h"
#include "buddies_talent_touches_data.h"
#include "Config.h"
#include "GameTime.h"
#include "GenericSpellActions.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Strategy.h"
#include <algorithm>
#include <cctype>
#include <map>
#include <mutex>
#include <string>

float BuddyForwardPassLean(uint32 guid, std::string const& spell);

namespace
{
    bool ForwardOn() { return sConfigMgr->GetOption<int32>("Buddies.ForwardPass", 0) == 1; }

    constexpr uint64 REBUILD_MS = 20000;
    constexpr uint32 PASS_MS    = 5000;

    int Measure() { return sConfigMgr->GetOption<int32>("Buddies.TalentWeights", 0); }
    float BroadShare() { return float(sConfigMgr->GetOption<int32>("Buddies.TalentWeights.Broad", 100)) / 100.0f; }

    struct Kept
    {
        uint64 at = 0;
        int measure = 0;
        std::map<std::string, float> weights;
    };
    std::map<uint32, Kept> sKept;
    std::mutex sKeptLock;

    std::map<std::string, float> WeightsFor(Player* bot, int measure)
    {
        std::lock_guard<std::mutex> guard(sKeptLock);
        uint64 now = GameTime::GetGameTimeMS().count();
        Kept& k = sKept[bot->GetGUID().GetCounter()];
        if (k.at != 0 && k.measure == measure && now - k.at < REBUILD_MS)
            return k.weights;
        std::map<uint32, std::pair<int, int>> points;
        for (BuddyTalentRanksRow const& r : BUDDY_TALENT_RANKS)
        {
            int ranks = 0, have = 0;
            for (int i = 0; i < 5; ++i)
                if (r.rank[i])
                {
                    ranks = i + 1;
                    if (bot->HasSpell(r.rank[i]))
                        have = i + 1;
                }
            if (have > 0)
                points[r.talent] = { have, ranks };
        }
        std::vector<BuddyTalentDraw::Touch> touches;
        for (BuddyTalentTouchRow const& t : BUDDY_TALENT_TOUCHES)
        {
            auto p = points.find(t.talent);
            if (p != points.end())
                touches.push_back({ t.ability, t.broad != 0, t.percent, p->second.second, p->second.first });
        }
        k.at = now;
        k.measure = measure;
        k.weights = BuddyTalentDraw::Weights(touches, measure, BroadShare());
        return k.weights;
    }

    class BuddyTalentMultiplier : public Multiplier
    {
    public:
        BuddyTalentMultiplier(PlayerbotAI* botAI) : Multiplier(botAI, "buddy talents") { }

        float GetValue(Action* action) override
        {
            int measure = Measure();
            bool talents = measure == 1 || measure == 2, forward = ForwardOn();
            if (!talents && !forward)
                return 1.0f;
            CastSpellAction* cast = dynamic_cast<CastSpellAction*>(action);
            if (!cast)
                return 1.0f;
            std::string name = cast->getSpell();
            std::transform(name.begin(), name.end(), name.begin(), [](unsigned char ch) { return std::tolower(ch); });
            float weight = 1.0f, lean = 1.0f;
            if (talents)
            {
                auto weights = WeightsFor(bot, measure);
                auto w = weights.find(name);
                weight = w == weights.end() ? 1.0f : w->second;
            }
            if (forward)
                lean = BuddyForwardPassLean(bot->GetGUID().GetCounter(), name);
            return lean * BuddyTalentDraw::Factor(weight * lean, rand_norm());
        }
    };

    class BuddyTalentsStrategy : public Strategy
    {
    public:
        BuddyTalentsStrategy(PlayerbotAI* botAI) : Strategy(botAI) { }
        std::string const getName() override { return "buddy talents"; }
        void InitMultipliers(std::vector<Multiplier*>& multipliers) override
        {
            multipliers.push_back(new BuddyTalentMultiplier(botAI));
        }
    };

    class buddies_talents_world : public WorldScript
    {
    public:
        buddies_talents_world() : WorldScript("buddies_talents_world") { }

        void OnUpdate(uint32 diff) override
        {
            _since += diff;
            if (_since < PASS_MS)
                return;
            _since = 0;
            bool want = Measure() == 1 || Measure() == 2 || ForwardOn();
            for (auto const& pair : BuddyRosterPairs())
            {
                Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(pair.first));
                if (!bot || !bot->IsInWorld())
                    continue;
                PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
                if (!ai)
                    continue;
                if (ai->HasStrategy("buddy talents", BOT_STATE_COMBAT) != want)
                    ai->ChangeStrategy(want ? "+buddy talents" : "-buddy talents", BOT_STATE_COMBAT);
            }
        }

    private:
        uint32 _since = 0;
    };
}

Strategy* NewBuddyTalentsStrategy(PlayerbotAI* ai) { return new BuddyTalentsStrategy(ai); }

void AddSC_buddies_talents()
{
    new buddies_talents_world();
}
