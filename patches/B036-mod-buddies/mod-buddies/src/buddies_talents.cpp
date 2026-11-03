/*
 * buddies_talents.cpp - buddies lean on the abilities their talents
 * improve, more often, not always (issue 625).
 *
 * For a general audience: the bot module answers each concern with a
 * fixed list of abilities and always takes the first it can. A buddy with
 * talents in Healing Touch should cast it more often when an ally is low,
 * and still cast the others sometimes. This adds a small combat strategy
 * to every buddy whose only part is a multiplier: each time the bot
 * chooses, every spell it might cast has its priority nudged by a random
 * draw weighted by the buddy's talents (buddies_talent_draw.h), within one
 * concern's answers, never across concerns.
 *
 * Switches (the server's config, read each pass, so a reload takes them):
 *   Buddies.TalentWeights        0 off (the default), 1 a fixed raise per
 *                                talent point, 2 the talent's own percent
 *                                where it states one (625, question 1:
 *                                both built, the owner chooses)
 *   Buddies.TalentWeights.Broad  a broad talent's share, in percent: 100
 *                                (the default) or 50 (625a, question 1)
 *
 * The fight's forward pass (625n, buddies_forward_pass.cpp) leans each cast
 * too, by the share of the party's gap it closes; with Buddies.ForwardPass
 * 1 the multiplier is on even while the talent weights are off: a cast's
 * priority is multiplied by its lean, and by the draw's random factor for
 * the talent weight and the lean together, so the choices differ from one
 * fight to the next (2026-10-31).
 */

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

// the forward pass's lean for one of a buddy's casts (buddies_forward_pass.cpp)
float BuddyForwardPassLean(uint32 guid, std::string const& spell);

namespace
{
    bool ForwardOn() { return sConfigMgr->GetOption<int32>("Buddies.ForwardPass", 0) == 1; }

    // {{{ the numbers
    // REBUILD_MS: how often a buddy's weights are worked out again from the
    //             talents it has (a talent learned or reset shows within it).
    // PASS_MS:    how often the strategy is put on or taken off buddies to
    //             match the switch.
    constexpr uint64 REBUILD_MS = 20000;
    constexpr uint32 PASS_MS    = 5000;
    // }}}

    // {{{ local function Measure()
    int Measure() { return sConfigMgr->GetOption<int32>("Buddies.TalentWeights", 0); }
    float BroadShare() { return float(sConfigMgr->GetOption<int32>("Buddies.TalentWeights.Broad", 100)) / 100.0f; }
    // }}}

    // {{{ the weights, per buddy
    // Worked out from the talents the buddy knows: for each talent in the
    // table, its points are the highest rank spell the buddy has. Kept a
    // while (REBUILD_MS), then worked out again.
    struct Kept
    {
        uint64 at = 0;
        int measure = 0;
        std::map<std::string, float> weights;
    };
    std::map<uint32, Kept> sKept;
    std::mutex sKeptLock;

    // {{{ local function WeightsFor()
    std::map<std::string, float> WeightsFor(Player* bot, int measure)
    {
        std::lock_guard<std::mutex> guard(sKeptLock);
        uint64 now = GameTime::GetGameTimeMS().count();
        Kept& k = sKept[bot->GetGUID().GetCounter()];
        if (k.at != 0 && k.measure == measure && now - k.at < REBUILD_MS)
            return k.weights;
        std::map<uint32, std::pair<int, int>> points;  // talent -> (points, ranks)
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
    // }}}
    // }}}

    // {{{ BuddyTalentMultiplier
    // Every spell the bot might cast now: its priority times the draw's
    // factor for its talent weight, and times the forward pass's lean.
    // Anything but a spell cast, or with both switches off, is left as it
    // is (1).
    class BuddyTalentMultiplier : public Multiplier
    {
    public:
        BuddyTalentMultiplier(PlayerbotAI* botAI) : Multiplier(botAI, "buddy talents") { }

        float GetValue(Action* action) override
        {
            int measure = Measure();
            bool talents = measure == 1 || measure == 2, forward = ForwardOn();
            if (!talents && !forward)
                return 1.0f;                           // both off: the bot module's own order
            CastSpellAction* cast = dynamic_cast<CastSpellAction*>(action);
            if (!cast)
                return 1.0f;                           // not a spell: movement, items, orders
            std::string name = cast->getSpell();
            std::transform(name.begin(), name.end(), name.begin(), [](unsigned char ch) { return std::tolower(ch); });
            // the talent weight (1 with the talent switch off) and the forward
            // pass's lean (1 with it off) make one weight for the draw, so the
            // choice among near-equal answers is drawn, never the same each
            // time (the owner, 2026-10-31: "if it played out the same way
            // everytime, then we aren't building it correctly"); the lean also
            // multiplies the priority itself, so it still counts across
            // answers of different priority
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
    // }}}

    // {{{ BuddyTalentsStrategy
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
    // }}}

    // {{{ buddies_talents_world
    // Every PASS_MS: the strategy on every buddy in the world while the
    // talent switch is 1 or 2 or the forward pass is on, off otherwise, in
    // combat (where the concerns are answered).
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
                    continue;                          // not yet under the bot module
                if (ai->HasStrategy("buddy talents", BOT_STATE_COMBAT) != want)
                    ai->ChangeStrategy(want ? "+buddy talents" : "-buddy talents", BOT_STATE_COMBAT);
            }
        }

    private:
        uint32 _since = 0;
    };
    // }}}
}

// {{{ the maker and the script
Strategy* NewBuddyTalentsStrategy(PlayerbotAI* ai) { return new BuddyTalentsStrategy(ai); }

void AddSC_buddies_talents()
{
    new buddies_talents_world();
}
// }}}
