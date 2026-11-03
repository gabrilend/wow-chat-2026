
#include "buddies.h"
#include "buddies_fight_replay.h"
#include "buddies_forward_pass.h"
#include "buddies_healer_seat.h"
#include "buddies_tank_load.h"
#include "AiFactory.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "Creature.h"
#include "GameTime.h"
#include "Group.h"
#include "Log.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <atomic>
#include <cmath>
#include <cstdio>
#include <condition_variable>
#include <deque>
#include <filesystem>
#include <fstream>
#include <map>
#include <mutex>
#include <set>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;
using namespace BuddyForwardPass;

namespace
{
    constexpr uint32 STEP_MS = 500;
    constexpr uint32 LEAN_STALE_MS = 3000;
    constexpr uint32 FIGHT_GAP_MS = 10000;

    bool Replaying() { return sConfigMgr->GetOption<int32>("Buddies.ForwardPass.Replay", 0) == 1; }

    bool On() { return sConfigMgr->GetOption<int32>("Buddies.ForwardPass", 0) == 1; }
    double Now() { return GameTime::GetGameTimeMS().count() / 1000.0; }

    struct Party
    {
        Memory memory;
        double lastStep = 0.0;
        bool fresh = false;
        Verdict verdict;
        double verdictAt = -1.0;
        std::vector<std::string> memberNames, enemyNames;
        std::vector<uint64> memberIds;
        bool pending = false;
        std::vector<BuddyFightState::Event> sinceLast;
        std::string replayFile;
        double firstMoneyAt = -1.0, firstMoney = 0.0;
        BuddySeat::Seats seats;
        std::set<uint64> saidOom;
        std::set<uint64> dryNow;
        BuddyTankLoad::Load load;
    };
    std::mutex sPartiesLock;
    std::unordered_map<uint32, Party> sParties;

    Group* GroupOf(Unit* u)
    {
        if (!u) return nullptr;
        Player* p = u->GetCharmerOrOwnerPlayerOrPlayerItself();
        return p ? p->GetGroup() : nullptr;
    }

    struct Job
    {
        uint32 party = 0; Snapshot snapshot; Memory memory; std::vector<std::string> members, enemies; std::vector<std::pair<int, uint32>> buddies;
        std::vector<BuddyFightState::Event> newEvents; std::string replayFile;
        double money = 0.0, goldPerHour = 0.0;
        BuddySeat::Seats seats;
    };

    struct Leaning { double at = -1.0; std::map<std::string, double> leans; std::map<std::string, uint64> targets; double lastTry = 0.0; };
    std::mutex sLeansLock;
    std::unordered_map<uint32, Leaning> sLeans;
    std::mutex sJobsLock;
    std::condition_variable sJobsReady;
    std::deque<Job> sJobs;
    std::vector<std::thread> sWorkers;
    std::atomic<bool> sStopping{ false };

    void Work()
    {
        for (;;)
        {
            Job job;
            {
                std::unique_lock<std::mutex> lock(sJobsLock);
                sJobsReady.wait(lock, [] { return sStopping.load() || !sJobs.empty(); });
                if (sStopping.load() && sJobs.empty()) return;
                job = std::move(sJobs.front());
                sJobs.pop_front();
            }
            Verdict v = Step(job.snapshot, job.memory);
            BuddySeat::Seats seats = BuddySeat::Now(job.snapshot, job.memory, job.seats, v.left);
            if (!job.replayFile.empty())
            {
                std::ofstream out(job.replayFile, std::ios::app);
                if (out) out << BuddyFightReplay::Write(job.newEvents, job.snapshot, v.shortfall, v.left, v.leftKnown ? 1 : 0);
                else LOG_ERROR("module", "buddies forward pass: cannot write the replay {} (Buddies.ForwardPass.Replay is 1; LogsDir and its buddies-fights folder must be writable)", job.replayFile);
            }
            for (auto const& [index, guid] : job.buddies)
            {
                std::map<std::string, int> to;
                std::map<std::string, double> leans = Leans(job.snapshot, job.memory, index, job.goldPerHour, &seats, &to);
                std::map<std::string, uint64> targets;
                for (auto const& [name, member] : to) targets[name] = job.snapshot.party[member].id;
                std::lock_guard<std::mutex> lock(sLeansLock);
                Leaning& l = sLeans[guid];
                l.at = job.snapshot.t;
                l.leans = std::move(leans);
                l.targets = std::move(targets);
            }
            std::lock_guard<std::mutex> lock(sPartiesLock);
            Party& p = sParties[job.party];
            p.load        = BuddyTankLoad::Of(job.snapshot, v);
            p.verdict     = std::move(v);
            p.verdictAt   = job.snapshot.t;
            p.memberIds.clear();
            for (Member const& m : job.snapshot.party) p.memberIds.push_back(m.id);
            p.memberNames = std::move(job.members);
            p.enemyNames  = std::move(job.enemies);
            p.pending     = false;
            p.seats       = seats;
            p.dryNow.clear();
            for (int i : seats.dry) p.dryNow.insert(job.snapshot.party[i].id);
        }
    }

    void StartWorkers()
    {
        if (!sWorkers.empty()) return;
        int32 n = std::max<int32>(1, sConfigMgr->GetOption<int32>("Buddies.ForwardPass.Threads", 2));
        for (int32 i = 0; i < n; ++i) sWorkers.emplace_back(Work);
    }

    std::vector<Mark> MarksOf(Unit* u)
    {
        std::vector<Mark> out;
        for (auto const& [spell, app] : u->GetAppliedAuras())
        {
            Aura const* a = app->GetBase();
            Mark k{ a->GetId(), a->GetDuration() > 0 ? a->GetDuration() / 1000.0 : 0.0, 1, a->GetCasterGUID().GetRawValue(), {} };
            for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                if (app->HasEffect(i))
                    if (AuraEffect const* e = a->GetEffect(i))
                        k.effects.push_back({ uint32(e->GetAuraType()), e->GetAmount(), e->GetMiscValue(), uint32(std::max(0, e->GetAmplitude())), 1 });
            if (!k.effects.empty()) out.push_back(std::move(k));
        }
        return out;
    }

    void TakeSnapshot(Player* leader, Group* group, Job& job)
    {
        Snapshot& s = job.snapshot;
        s.t = Now();
        std::map<uint64, Unit*> enemies;
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* p = ref->GetSource();
            if (!p || !p->IsInWorld() || p->GetMap() != leader->GetMap()) continue;
            Member m;
            m.id = p->GetGUID().GetRawValue();
            m.health = p->GetHealth(); m.maxHealth = p->GetMaxHealth();
            m.resourceKind = uint8(p->getPowerType());
            m.resource = p->GetPower(p->getPowerType()); m.maxResource = p->GetMaxPower(p->getPowerType());
            m.cls = p->getClass(); m.level = p->GetLevel(); m.armour = p->GetArmor();
            m.role = PlayerbotAI::IsTank(p) ? 1 : (PlayerbotAI::IsHeal(p) ? 2 : 0);
            m.x = p->GetPositionX(); m.y = p->GetPositionY(); m.z = p->GetPositionZ();
            m.marks = MarksOf(p);
            job.money += double(p->GetMoney());
            for (auto const& [tab, points] : AiFactory::GetPlayerSpecTabs(p))
            {
                m.talentPoints = uint8(std::min<uint32>(255, m.talentPoints + points));
                if (BuddySeat::HealingTree(m.cls, tab)) m.healPoints = uint8(std::min<uint32>(255, m.healPoints + points));
            }
            m.baseMana = p->GetCreateMana();
            for (BuddyAbilityRow const& r : BUDDY_ABILITIES)
            {
                if (r.cls != m.cls || r.cooldownMs < 90000) continue;
                for (uint32 id = sSpellMgr->GetFirstSpellInChain(r.spell); id; id = sSpellMgr->GetNextSpellInChain(id))
                    if (p->HasSpell(id))
                    {
                        m.cooldowns.push_back({ id, r.name, p->GetSpellCooldownDelay(id) / 1000.0 });
                        break;
                    }
            }
            int scene = BuddySceneForwardPass(p->GetGUID().GetCounter());
            bool companion = p->GetSession() && (BuddyIsCompanionAccount(p->GetSession()->GetAccountId()) || BuddyIsStandInAccount(p->GetSession()->GetAccountId()));
            if (scene == 1 || (scene < 0 && companion))
                job.buddies.push_back({ int(s.party.size()), p->GetGUID().GetCounter() });
            s.party.push_back(std::move(m));
            job.members.push_back(p->GetName());
            for (Unit* attacker : p->getAttackers())
                if (attacker && attacker->IsInWorld() && attacker->IsAlive()) enemies[attacker->GetGUID().GetRawValue()] = attacker;
        }
        for (auto const& [id, u] : enemies)
        {
            Enemy e;
            e.id = id;
            e.health = u->GetHealth(); e.maxHealth = u->GetMaxHealth();
            e.level = u->GetLevel();
            if (Creature* c = u->ToCreature()) e.rank = uint8(c->GetCreatureTemplate()->rank);
            if (BuddySceneIsBoss(id)) e.rank = 3;
            e.attacking = u->GetVictim() ? u->GetVictim()->GetGUID().GetRawValue() : 0;
            e.marks = MarksOf(u);
            if (Spell* cast = u->GetCurrentSpell(CURRENT_GENERIC_SPELL))
                if (cast->getState() == SPELL_STATE_PREPARING)
                    if (SpellInfo const* info = cast->GetSpellInfo())
                    {
                        e.casting  = info->Id;
                        e.castLeft = std::max(0, cast->GetCastTimeRemaining()) / 1000.0;
                        Unit* on   = cast->m_targets.GetUnitTarget();
                        e.castOn   = on ? on->GetGUID().GetRawValue() : 0;
                        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                            if (info->Effects[i].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
                                e.castDamage += std::max(0, info->Effects[i].CalcValue(u));
                    }
            for (ThreatReference const* ref : u->GetThreatMgr().GetSortedThreatList())
            {
                Unit* who = ref->GetVictim();
                if (!who) continue;
                int state = ref->IsOnline() ? 2 : (ref->IsSuppressed() ? 1 : 0);
                int taunt = ref->IsTaunting() ? 1 : (ref->IsDetaunted() ? -1 : 0);
                e.threat.push_back({ who->GetGUID().GetRawValue(), { ref->GetThreat(), state, taunt, u->IsWithinMeleeRange(who) } });
            }
            s.enemies.push_back(std::move(e));
            job.enemies.push_back(u->GetName());
        }
    }

    class buddies_forward_pass_unit : public UnitScript
    {
    public:
        buddies_forward_pass_unit() : UnitScript("buddies_forward_pass_unit", true, { UNITHOOK_ON_HEAL }) { }

        uint32 DealDamage(Unit* attacker, Unit* victim, uint32 damage, DamageEffectType type) override
        {
            if (!damage || !attacker || !victim || attacker == victim || !On()) return damage;
            Group* g = GroupOf(victim);
            if (!g) g = GroupOf(attacker);
            if (!g) return damage;
            BuddyFightState::Event e{ Now(), BuddyFightState::HIT, attacker->GetGUID().GetRawValue(), victim->GetGUID().GetRawValue(), 0, double(damage), type == DIRECT_DAMAGE };
            std::lock_guard<std::mutex> lock(sPartiesLock);
            Party& p = sParties[g->GetGUID().GetCounter()];
            p.memory.Add(e);
            p.fresh = true;
            if (Replaying()) p.sinceLast.push_back(e);
            return damage;
        }

        void OnHeal(Unit* healer, Unit* receiver, uint32& gain) override
        {
            if (!gain || !receiver || !On()) return;
            Group* g = GroupOf(receiver);
            if (!g) return;
            BuddyFightState::Event e{ Now(), BuddyFightState::HEAL, healer ? healer->GetGUID().GetRawValue() : 0, receiver->GetGUID().GetRawValue(), 0, double(gain), false };
            std::lock_guard<std::mutex> lock(sPartiesLock);
            Party& p = sParties[g->GetGUID().GetCounter()];
            p.memory.Add(e);
            p.fresh = true;
            if (Replaying()) p.sinceLast.push_back(e);
        }
    };

    void HandOutBuffs(Player* bot)
    {
        std::vector<std::pair<std::string, uint64>> todo;
        {
            std::lock_guard<std::mutex> lock(sLeansLock);
            auto it = sLeans.find(bot->GetGUID().GetCounter());
            if (it == sLeans.end() || it->second.targets.empty()) return;
            double now = Now();
            if ((now - it->second.at) * 1000.0 > LEAN_STALE_MS || now - it->second.lastTry < 1.0) return;
            it->second.lastTry = now;
            for (auto const& [name, id] : it->second.targets)
            {
                auto lean = it->second.leans.find(name);
                if (lean != it->second.leans.end() && lean->second > 1.0) todo.push_back({ name, id });
            }
        }
        if (todo.empty() || !bot->IsAlive() || bot->IsNonMeleeSpellCast(false)) return;
        PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
        if (!ai) return;
        for (auto const& [name, id] : todo)
        {
            Unit* target = ObjectAccessor::GetUnit(*bot, ObjectGuid(id));
            if (!target || !target->IsAlive()) continue;
            if (ai->CanCastSpell(name, target) && ai->CastSpell(name, target)) return;
        }
    }

    class buddies_forward_pass_player : public PlayerScript
    {
    public:
        buddies_forward_pass_player() : PlayerScript("buddies_forward_pass_player", { PLAYERHOOK_ON_UPDATE }) { }

        void OnPlayerUpdate(Player* player, uint32 ) override
        {
            if (!On()) return;
            if (player->IsInCombat()) HandOutBuffs(player);
            Group* g = player->GetGroup();
            if (!g || g->GetLeaderGUID() != player->GetGUID()) return;
            bool fighting = false;
            for (GroupReference* ref = g->GetFirstMember(); ref && !fighting; ref = ref->next())
                if (Player* p = ref->GetSource()) fighting = p->IsInWorld() && p->IsInCombat();
            if (!fighting) return;
            uint32 id = g->GetGUID().GetCounter();
            double now = Now();
            {
                std::lock_guard<std::mutex> lock(sPartiesLock);
                Party& p = sParties[id];
                if (p.pending || !p.fresh || (now - p.lastStep) * 1000.0 < STEP_MS) return;
                bool newFight = (now - p.lastStep) * 1000.0 >= FIGHT_GAP_MS;
                if (newFight) { p.seats = BuddySeat::Seats(); p.saidOom.clear(); p.dryNow.clear(); }
                if (!Replaying()) p.replayFile.clear();
                else if (newFight || p.replayFile.empty())
                {
                    std::string dir = sConfigMgr->GetOption<std::string>("LogsDir", "") + "/buddies-fights";
                    std::error_code ec;
                    std::filesystem::create_directories(dir, ec);
                    p.replayFile = dir + "/fight-" + std::to_string(id) + "-" + std::to_string(uint64(GameTime::GetGameTime().count())) + ".replay";
                }
                p.lastStep = now;
                p.fresh = false;
                p.pending = true;
            }
            Job job;
            job.party = id;
            TakeSnapshot(player, g, job);
            double health = 0;
            for (Enemy const& e : job.snapshot.enemies) health += e.health;
            {
                std::lock_guard<std::mutex> lock(sPartiesLock);
                Party& p = sParties[id];
                p.memory.Forget(job.snapshot.t);
                p.memory.Sample(job.snapshot.t, health);
                for (Member const& m : job.snapshot.party) p.memory.SampleResource(m.id, job.snapshot.t, m.resource);
                job.memory = p.memory;
                job.seats = p.seats;
                auto say = [&](uint64 id, char const* word) {
                    Player* who = ObjectAccessor::FindPlayer(ObjectGuid(id));
                    if (!who || !who->GetSession()) return false;
                    uint32 account = who->GetSession()->GetAccountId();
                    if (!BuddyIsCompanionAccount(account) && !BuddyIsStandInAccount(account)) return true;
                    WorldPacket data;
                    ChatHandler::BuildChatPacket(data, CHAT_MSG_PARTY, LANG_UNIVERSAL, who, nullptr, word);
                    g->BroadcastPacket(&data, false);
                    return true;
                };
                for (uint64 id : p.dryNow) if (!p.saidOom.count(id) && say(id, "oom")) p.saidOom.insert(id);
                for (auto it = p.saidOom.begin(); it != p.saidOom.end(); )
                    if (!p.dryNow.count(*it)) { say(*it, "ready"); it = p.saidOom.erase(it); }
                    else ++it;
                job.newEvents = std::move(p.sinceLast);
                p.sinceLast.clear();
                job.replayFile = p.replayFile;
                if (p.firstMoneyAt < 0) { p.firstMoneyAt = job.snapshot.t; p.firstMoney = job.money; }
                double since = job.snapshot.t - p.firstMoneyAt;
                job.goldPerHour = since >= 60.0 ? std::max(0.0, (job.money - p.firstMoney) / since * 3600.0) : 0.0;
            }
            StartWorkers();
            {
                std::lock_guard<std::mutex> lock(sJobsLock);
                sJobs.push_back(std::move(job));
            }
            sJobsReady.notify_one();
        }
    };

    class buddies_forward_pass_world : public WorldScript
    {
    public:
        buddies_forward_pass_world() : WorldScript("buddies_forward_pass_world") { }

        void OnShutdown() override
        {
            sStopping = true;
            sJobsReady.notify_all();
            for (std::thread& t : sWorkers) if (t.joinable()) t.join();
            sWorkers.clear();
        }
    };

    class buddies_forward_pass_command : public CommandScript
    {
    public:
        buddies_forward_pass_command() : CommandScript("buddies_forward_pass_command") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable commandTable =
            {
                { "buddy fight", HandleFight, SEC_GAMEMASTER, Console::No },
            };
            return commandTable;
        }

        static bool HandleFight(ChatHandler* handler)
        {
            Player* me = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
            Group* g = me ? me->GetGroup() : nullptr;
            if (!On())
            {
                handler->SendSysMessage("The forward pass is off (Buddies.ForwardPass 0).");
                return true;
            }
            if (!g)
            {
                handler->SendSysMessage("You're not in a party: the forward pass works per party.");
                return true;
            }
            std::lock_guard<std::mutex> lock(sPartiesLock);
            auto it = sParties.find(g->GetGUID().GetCounter());
            if (it == sParties.end() || it->second.verdictAt < 0)
            {
                handler->SendSysMessage("No verdict yet: one is worked out every half second while your party fights.");
                return true;
            }
            Party const& p = it->second;
            Verdict const& v = p.verdict;
            handler->PSendSysMessage("Fight ({} s ago): {}; {} s left{}; the party is {} health short ({}).",
                uint32(Now() - p.verdictAt), v.kind == BuddyPlan::Fight::Boss ? "a boss fight" : "trash",
                uint32(v.left), v.leftKnown ? "" : " (end not seen: the horizon)", uint32(v.shortfall),
                v.shortfall < 1.0 ? "curves toward victory" : "a death coming");
            for (size_t i = 0; i < v.incoming.size() && i < p.memberNames.size(); ++i)
                handler->PSendSysMessage("  {}: {} a second coming at it, {}% let through by armour, healed {} a second, {}",
                    p.memberNames[i], uint32(v.incoming[i]), uint32(v.taken[i] * 100), uint32(v.healing[i]),
                    std::isinf(v.timeToDeath[i]) ? std::string("holding") : ("dead in " + std::to_string(uint32(v.timeToDeath[i])) + " s"));
            for (size_t e = 0; e < v.attention.size() && e < p.enemyNames.size(); ++e)
                handler->PSendSysMessage("  {} ({} a second, real) attacks {}", p.enemyNames[e], uint32(v.hits[e]),
                    v.attention[e] >= 0 && size_t(v.attention[e]) < p.memberNames.size() ? p.memberNames[v.attention[e]] : std::string("no one"));
            if (p.load.tank >= 0 && size_t(p.load.tank) < p.memberNames.size())
                handler->PSendSysMessage("  Load: {} holds {}; with one more like them it would end at {} health: {}",
                    p.memberNames[p.load.tank], p.load.enemies, std::isfinite(p.load.room) ? std::to_string(int64(p.load.room)) : std::string("nothing (the end not seen)"),
                    p.load.room > 0 ? "room to pull more" : "hold");
            if (v.tanks.holder >= 0 && size_t(v.tanks.holder) < p.memberNames.size())
                handler->PSendSysMessage("  Tanks: {} should hold the hardest hitter{}", p.memberNames[v.tanks.holder],
                    v.tanks.to >= 0 && size_t(v.tanks.to) < p.memberNames.size()
                        ? (", handing to " + p.memberNames[v.tanks.to] + " in " + std::to_string(uint32(v.tanks.at)) + " s") : std::string(""));
            return true;
        }
    };
}

float BuddyForwardPassLean(uint32 guid, std::string const& spell)
{
    if (!On()) return 1.0f;
    std::lock_guard<std::mutex> lock(sLeansLock);
    auto it = sLeans.find(guid);
    if (it == sLeans.end() || (Now() - it->second.at) * 1000.0 > LEAN_STALE_MS) return 1.0f;
    if (it->second.targets.count(spell)) return 0.05f;
    auto l = it->second.leans.find(spell);
    return l == it->second.leans.end() ? 1.0f : float(l->second);
}

int BuddyForwardPassTankRoom(uint32 groupId)
{
    if (!On()) return -1;
    std::lock_guard<std::mutex> lock(sPartiesLock);
    auto it = sParties.find(groupId);
    if (it == sParties.end() || it->second.verdictAt < 0 || (Now() - it->second.verdictAt) * 1000.0 > LEAN_STALE_MS || it->second.load.tank < 0) return -1;
    return it->second.load.room > 0 ? 1 : 0;
}

std::string BuddyForwardPassFrameColumns()
{
    return "fp-age\tfp-kind\tfp-left\tfp-shortfall\tfp-incoming\tfp-healing\tfp-time-to-death\tfp-short-of\tfp-seat\tfp-seats-short\tfp-tank-room\tfp-leans\tfp-buffs";
}
std::string BuddyForwardPassFrame(Player* who)
{
    constexpr int COLUMNS = 13;
    std::vector<std::string> f(COLUMNS, "-");
    auto join = [&]() { std::string out; for (int i = 0; i < COLUMNS; ++i) out += (i ? "\t" : "") + f[i]; return out; };
    auto num  = [](double v, int places) { if (!std::isfinite(v)) return std::string("inf"); char b[48]; std::snprintf(b, sizeof b, "%.*f", places, v); return std::string(b); };
    Group* g = who ? who->GetGroup() : nullptr;
    if (!On() || !g) return join();
    uint64 raw = who->GetGUID().GetRawValue();
    std::vector<std::string> names;
    std::vector<uint64> ids;
    {
        std::lock_guard<std::mutex> lock(sPartiesLock);
        auto it = sParties.find(g->GetGUID().GetCounter());
        if (it == sParties.end() || it->second.verdictAt < 0) return join();
        Party const& p = it->second;
        Verdict const& v = p.verdict;
        int i = -1;
        for (size_t k = 0; k < p.memberIds.size(); ++k) if (p.memberIds[k] == raw) i = int(k);
        f[0] = num(Now() - p.verdictAt, 1);
        f[1] = v.kind == BuddyPlan::Fight::Boss ? "boss" : "trash";
        f[2] = v.leftKnown ? num(v.left, 1) : "?";
        f[3] = num(v.shortfall, 0);
        if (i >= 0)
        {
            if (size_t(i) < v.incoming.size())    f[4] = num(v.incoming[i], 0);
            if (size_t(i) < v.healing.size())     f[5] = num(v.healing[i], 0);
            if (size_t(i) < v.timeToDeath.size()) f[6] = num(v.timeToDeath[i], 1);
            if (size_t(i) < v.shortOf.size())     f[7] = num(v.shortOf[i], 0);
            f[8] = BuddySeat::Has(p.seats.holders, i) ? "holder" : BuddySeat::Has(p.seats.dry, i) ? "dry" : "-";
            if (p.load.tank == i) f[10] = num(p.load.room, 0);
        }
        f[9] = p.seats.short_ ? "1" : "0";
        names = p.memberNames;
        ids = p.memberIds;
    }
    std::lock_guard<std::mutex> lock(sLeansLock);
    auto it = sLeans.find(who->GetGUID().GetCounter());
    if (it == sLeans.end()) return join();
    std::string leans, buffs;
    for (auto const& [name, lean] : it->second.leans)
        if (std::fabs(lean - 1.0) > 1e-3) leans += (leans.empty() ? "" : ";") + name + "=" + num(lean, 3);
    for (auto const& [name, to] : it->second.targets)
    {
        std::string whom = "?";
        for (size_t k = 0; k < ids.size() && k < names.size(); ++k) if (ids[k] == to) whom = names[k];
        buffs += (buffs.empty() ? "" : ";") + name + ">" + whom;
    }
    if (!leans.empty()) f[11] = leans;
    if (!buffs.empty()) f[12] = buffs;
    return join();
}

void AddSC_buddies_forward_pass()
{
    new buddies_forward_pass_unit();
    new buddies_forward_pass_player();
    new buddies_forward_pass_world();
    new buddies_forward_pass_command();
}
