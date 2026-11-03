
#include "buddies.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Group.h"
#include "GroupMgr.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "Spell.h"
#include "TemporarySummon.h"
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <string>
#include <vector>

using namespace Acore::ChatCommands;

std::string BuddyForwardPassFrameColumns();
std::string BuddyForwardPassFrame(Player* who);

namespace
{
    constexpr uint32 PASS_MS       = 500;
    constexpr uint64 ROUND_MOST_MS = 600000;
    constexpr float  MONSTER_AHEAD = 12.0f;
    constexpr float  CIRCLE        = 4.0f;
    constexpr uint64 BREATH_MS     = 5000;

    struct Seat { uint8 role; bool forward; int sameClassAs; };
    struct Kind
    {
        char const* name;
        uint8 botLevel, monsterLevel, monsterRank;
        bool boss;
        std::vector<Seat> seats;
    };
    std::vector<Kind> const KINDS = {
        { "duel",    40, 45, 0, false, { { 0, false, -1 }, { 0, true, 0 } } },
        { "party60", 60, 65, 1, true,  { { 1, true, -1 }, { 2, true, -1 }, { 0, true, -1 } } },
        { "party30", 30, 35, 1, true,  { { 1, true, -1 }, { 2, true, -1 }, { 0, true, -1 } } },
        { "party15", 15, 20, 1, true,  { { 1, true, -1 }, { 2, true, -1 }, { 0, true, -1 } } },
    };

    enum class Stage { NONE, BRINGING, FIGHTING, BREATH };
    struct Tally { double dealt = 0, taken = 0, healed = 0; bool fell = false; std::string casts; };
    struct Scene
    {
        Kind const* kind = nullptr;
        bool redraw = false;
        Stage stage = Stage::NONE;
        uint32 gm = 0;
        uint32 map = 0; float x = 0, y = 0, z = 0, o = 0;
        std::vector<uint32> bots;
        uint8 drawnClass = 0;
        ObjectGuid monster;
        uint32 monsterEntry = 0;
        uint32 round = 0;
        uint64 since = 0;
        std::vector<Tally> tally;
        Tally monsterTally;
        uint32 frame = 0;
    };
    Scene sScene;
    std::ofstream sFrames;
    std::mutex sTallyLock;

    Player* Bot(uint32 low) { return low ? ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(low)) : nullptr; }
    int SeatOf(uint32 low)
    {
        for (size_t i = 0; i < sScene.bots.size(); ++i) if (sScene.bots[i] == low) return int(i);
        return -1;
    }

    uint32 PickMonster(uint8 level, uint8 rank)
    {
        QueryResult r = WorldDatabase.Query(
            "SELECT entry FROM creature_template WHERE minlevel = {} AND maxlevel = {} AND `rank` = {} AND type = 7 AND unit_class = 1 "
            "AND ScriptName = '' AND AIName = '' AND npcflag = 0 AND (unit_flags & 33555202) = 0 ORDER BY entry LIMIT 1",
            uint32(level), uint32(level), uint32(rank));
        return r ? (*r)[0].Get<uint32>() : 0;
    }
    Creature* Monster(Player* near) { return near ? ObjectAccessor::GetCreature(*near, sScene.monster) : nullptr; }

    void Write(char const* how, uint64 ms, Creature* monster)
    {
        std::string dir = sConfigMgr->GetOption<std::string>("LogsDir", "") + "/buddies-scenes";
        std::error_code ec;
        std::filesystem::create_directories(dir, ec);
        std::string path = dir + "/" + sScene.kind->name + ".tsv";
        bool fresh = !std::filesystem::exists(path, ec);
        std::ofstream out(path, std::ios::app);
        if (!out)
        {
            LOG_ERROR("module", "mod-buddies: scene {}: cannot write {} (LogsDir must be writable)", sScene.kind->name, path);
            return;
        }
        if (fresh) out << "# made by the buddy module's fight scenes (buddies_scenes.cpp, issue 176a3): one line per stand-in per round\n"
                          "when\tround\tseconds\tended\tstand-in\tclass\tforward\tdealt\ttaken\thealed\tfell\tmonster-left\n";
        double left = monster && monster->GetMaxHealth() ? 100.0 * monster->GetHealth() / monster->GetMaxHealth() : 0.0;
        std::lock_guard<std::mutex> lock(sTallyLock);
        for (size_t i = 0; i < sScene.bots.size(); ++i)
        {
            Player* b = Bot(sScene.bots[i]);
            Tally const& t = sScene.tally[i];
            out << GameTime::GetGameTime().count() << '\t' << sScene.round << '\t' << ms / 1000.0 << '\t' << how << '\t'
                << (b ? b->GetName() : std::string("?")) << '\t' << (b ? uint32(b->getClass()) : 0) << '\t' << (sScene.kind->seats[i].forward ? 1 : 0) << '\t'
                << uint64(t.dealt) << '\t' << uint64(t.taken) << '\t' << uint64(t.healed) << '\t' << (t.fell ? 1 : 0) << '\t' << int(left) << '\n';
        }
    }

    char const* const FRAME_COLUMNS =
        "when\tround\tframe\tt\twho\tside\tseat\tclass\trole\tforward\talive\tcombat\thealth\tmax-health\tpower-kind\tpower\tmax-power\t"
        "x\ty\tz\tfacing\tmoving\tdistance\ttarget\tattacking\tcasting\tcast-left\tauras\tthreat\tdealt\ttaken\thealed\tcasts";

    std::string Clean(std::string text)
    {
        for (char& c : text) if (c == '\t' || c == '\n' || c == '\r' || c == ';' || c == ':' || c == '>') c = ' ';
        return text;
    }
    std::string Num(double v, int places) { char b[48]; std::snprintf(b, sizeof b, "%.*f", places, v); return b; }
    std::string NameOf(Unit* near, ObjectGuid guid)
    {
        if (guid.IsEmpty()) return "-";
        Unit* u = ObjectAccessor::GetUnit(*near, guid);
        return u ? Clean(u->GetName()) : "?";
    }
    std::string Auras(Unit* u)
    {
        std::string out;
        for (auto const& [id, app] : u->GetAppliedAuras())
        {
            Aura const* a = app->GetBase();
            if (!a) continue;
            int32 ms = a->GetDuration();
            Unit* from = a->GetCaster();
            out += (out.empty() ? "" : ";") + std::to_string(id) + ":" + Clean(a->GetSpellInfo()->SpellName[0]) + ":" +
                   std::to_string(uint32(a->GetStackAmount())) + ":" + (ms < 0 ? std::string("-1") : Num(ms / 1000.0, 1)) + ":" +
                   (from ? Clean(from->GetName()) : std::string("?")) + ":" + (app->IsPositive() ? "+" : "-");
        }
        return out.empty() ? "-" : out;
    }
    std::string Casting(Unit* u, int32& left)
    {
        left = 0;
        Spell* sp = u->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
        if (!sp) sp = u->GetCurrentSpell(CURRENT_GENERIC_SPELL);
        if (!sp) return "-";
        left = sp->GetCastTimeRemaining();
        return std::to_string(sp->GetSpellInfo()->Id) + ":" + Clean(sp->GetSpellInfo()->SpellName[0]);
    }

    void OpenFrames()
    {
        std::string dir = sConfigMgr->GetOption<std::string>("LogsDir", "") + "/buddies-scenes";
        std::error_code ec;
        std::filesystem::create_directories(dir, ec);
        std::string path = dir + "/" + sScene.kind->name + "-frames.tsv";
        bool fresh = !std::filesystem::exists(path, ec);
        sFrames.close();
        sFrames.clear();
        sFrames.open(path, std::ios::app);
        if (!sFrames)
        {
            LOG_ERROR("module", "mod-buddies: scene {}: cannot write {} (LogsDir must be writable)", sScene.kind->name, path);
            return;
        }
        if (fresh)
            sFrames << "# made by the buddy module's fight scenes (buddies_scenes.cpp, issue 176a3): every combatant's state, one line each per frame ("
                    << PASS_MS << " ms), for a chart per combatant\n"
                    << FRAME_COLUMNS << '\t' << BuddyForwardPassFrameColumns() << '\n';
    }

    void Frame(Creature* monster, uint64 now)
    {
        if (!sFrames) return;
        ++sScene.frame;
        std::string head = std::to_string(GameTime::GetGameTime().count()) + "\t" + std::to_string(sScene.round) + "\t" +
                           std::to_string(sScene.frame) + "\t" + Num((now - sScene.since) / 1000.0, 1) + "\t";
        auto state = [&](Unit* u, std::string const& side) -> std::string
        {
            int32 left = 0;
            std::string casting = Casting(u, left);
            Unit* other = u == monster ? u->GetVictim() : monster;
            Powers kind = u->getPowerType();
            return Clean(u->GetName()) + "\t" + side + "\t" + std::to_string(u->IsAlive() ? 1 : 0) + "\t" + std::to_string(u->IsInCombat() ? 1 : 0) + "\t" +
                   std::to_string(u->GetHealth()) + "\t" + std::to_string(u->GetMaxHealth()) + "\t" + std::to_string(uint32(kind)) + "\t" +
                   std::to_string(u->GetPower(kind)) + "\t" + std::to_string(u->GetMaxPower(kind)) + "\t" +
                   Num(u->GetPositionX(), 2) + "\t" + Num(u->GetPositionY(), 2) + "\t" + Num(u->GetPositionZ(), 2) + "\t" + Num(u->GetOrientation(), 3) + "\t" +
                   std::to_string(u->isMoving() ? 1 : 0) + "\t" + (other ? Num(u->GetDistance(other), 2) : std::string("-")) + "\t" +
                   NameOf(u, u->GetTarget()) + "\t" + (u->GetVictim() ? Clean(u->GetVictim()->GetName()) : std::string("-")) + "\t" +
                   casting + "\t" + std::to_string(left) + "\t" + Auras(u);
        };
        std::lock_guard<std::mutex> lock(sTallyLock);
        for (size_t i = 0; i < sScene.bots.size(); ++i)
        {
            Player* b = Bot(sScene.bots[i]);
            if (!b || i >= sScene.tally.size()) continue;
            Tally& t = sScene.tally[i];
            Seat const& seat = sScene.kind->seats[i];
            std::string side = "stand-in\t" + std::to_string(i) + "\t" + std::to_string(uint32(b->getClass())) + "\t" +
                               std::to_string(uint32(seat.role)) + "\t" + (seat.forward ? "1" : "0");
            sFrames << head << state(b, side) << '\t' << (monster ? Num(monster->GetThreatMgr().GetThreat(b), 0) : std::string("-")) << '\t'
                    << uint64(t.dealt) << '\t' << uint64(t.taken) << '\t' << uint64(t.healed) << '\t' << (t.casts.empty() ? std::string("-") : t.casts) << '\t'
                    << BuddyForwardPassFrame(b) << '\n';
            t.casts.clear();
        }
        if (monster)
        {
            Tally const& t = sScene.monsterTally;
            sFrames << head << state(monster, "monster\t-\t" + std::to_string(uint32(monster->getClass())) + "\t-\t-") << "\t-\t"
                    << uint64(t.dealt) << '\t' << uint64(t.taken) << '\t' << uint64(t.healed) << "\t-\t" << BuddyForwardPassFrame(nullptr) << '\n';
        }
        sFrames.flush();
    }

    void Tell(std::string const& text)
    {
        if (Player* gm = Bot(sScene.gm))
            ChatHandler(gm->GetSession()).SendSysMessage(text);
    }

    bool Bring(Player* gm)
    {
        bool all = true;
        for (size_t i = 0; i < sScene.kind->seats.size(); ++i)
        {
            Seat const& seat = sScene.kind->seats[i];
            if (!sScene.bots[i])
            {
                uint8 cls = 0;
                if (seat.sameClassAs >= 0)
                {
                    if (!sScene.drawnClass) { all = false; continue; }
                    cls = sScene.drawnClass;
                }
                std::string said;
                sScene.bots[i] = BuddyBringStandIn(gm->GetTeamId() == TEAM_HORDE ? 1 : 0, seat.role, sScene.kind->botLevel, 0, cls,
                                                   sScene.map, sScene.x, sScene.y, sScene.z, sScene.o, said);
                if (!sScene.bots[i]) { Tell("Scene: a stand-in could not be brought (" + said + "); trying again."); all = false; continue; }
            }
            if (BuddyStandInOnItsWay(sScene.bots[i])) { all = false; continue; }
            Player* b = Bot(sScene.bots[i]);
            if (!b || !b->IsInWorld()) { all = false; continue; }
            if (i == 0 && !sScene.drawnClass) sScene.drawnClass = b->getClass();
        }
        return all;
    }

    void Party()
    {
        Player* lead = Bot(sScene.bots[0]);
        if (!lead) return;
        Group* g = lead->GetGroup();
        if (!g || g->GetLeaderGUID() != lead->GetGUID())
        {
            if (g) g->RemoveMember(lead->GetGUID());
            g = new Group;
            if (!g->Create(lead)) { delete g; LOG_ERROR("module", "mod-buddies: scene {}: no party could be made", sScene.kind->name); return; }
            sGroupMgr->AddGroup(g);
        }
        for (size_t i = 1; i < sScene.bots.size(); ++i)
            if (Player* b = Bot(sScene.bots[i]))
                if (b->GetGroup() != g)
                {
                    if (Group* old = b->GetGroup()) old->RemoveMember(b->GetGUID());
                    g->AddMember(b);
                }
    }

    void Begin(Player* gm)
    {
        if (Creature* old = Monster(gm)) old->DespawnOrUnsummon();
        sScene.monster.Clear();
        Party();
        for (size_t i = 0; i < sScene.bots.size(); ++i)
        {
            Player* b = Bot(sScene.bots[i]);
            if (!b) continue;
            if (b->isDead()) { b->ResurrectPlayer(1.0f); b->SpawnCorpseBones(); }
            b->CombatStop(true);
            b->RemoveAllAurasOnDeath();
            b->SetFullHealth();
            b->SetPower(b->getPowerType(), b->GetMaxPower(b->getPowerType()));
            b->RemoveAllSpellCooldown();
            float a = float(rand_norm()) * 6.2831853f;
            b->NearTeleportTo(sScene.x + std::cos(a) * CIRCLE, sScene.y + std::sin(a) * CIRCLE, sScene.z, sScene.o);
            if (PlayerbotAI* ai = GET_PLAYERBOT_AI(b))
            {
                if (ai->GetMaster() != gm) ai->SetMaster(gm);
                if (!ai->HasStrategy("stay", BOT_STATE_NON_COMBAT)) ai->ChangeStrategy("+stay", BOT_STATE_NON_COMBAT);
            }
        }
        float mx = sScene.x + std::cos(sScene.o) * MONSTER_AHEAD, my = sScene.y + std::sin(sScene.o) * MONSTER_AHEAD;
        Creature* m = gm->SummonCreature(sScene.monsterEntry, mx, my, sScene.z, sScene.o + 3.14159265f, TEMPSUMMON_MANUAL_DESPAWN);
        if (!m) { Tell("Scene: the monster could not be summoned; stopped."); sScene.stage = Stage::NONE; return; }
        m->SetFaction(14);
        sScene.monster = m->GetGUID();
        {
            std::lock_guard<std::mutex> lock(sTallyLock);
            sScene.tally.assign(sScene.bots.size(), Tally());
            sScene.monsterTally = Tally();
        }
        sScene.frame = 0;
        Player* first = Bot(sScene.bots[0]);
        for (uint32 low : sScene.bots)
            if (Player* b = Bot(low)) m->GetThreatMgr().AddThreat(b, 1.0f);
        if (first && m->AI()) m->AI()->AttackStart(first);
        ++sScene.round;
        sScene.stage = Stage::FIGHTING;
        sScene.since = GameTime::GetGameTimeMS().count();
    }

    void Watch(Player* gm, uint64 now)
    {
        Creature* m = Monster(gm);
        bool monsterDown = !m || m->isDead();
        bool partyDown = true;
        {
            std::lock_guard<std::mutex> lock(sTallyLock);
            for (size_t i = 0; i < sScene.bots.size(); ++i)
            {
                Player* b = Bot(sScene.bots[i]);
                if (b && b->isDead()) sScene.tally[i].fell = true;
                if (b && b->IsAlive()) partyDown = false;
            }
        }
        Frame(m, now);
        uint64 ms = now - sScene.since;
        char const* how = monsterDown ? "monster-down" : partyDown ? "party-down" : ms >= ROUND_MOST_MS ? "undecided" : nullptr;
        if (!how) return;
        Write(how, ms, m);
        if (m && !m->isDead()) m->DespawnOrUnsummon();
        if (sScene.redraw)
        {
            for (uint32& low : sScene.bots) { if (low) BuddyDismissStandIn(low); low = 0; }
            sScene.drawnClass = 0;
            sScene.stage = Stage::BRINGING;
        }
        else
            sScene.stage = Stage::BREATH;
        sScene.since = now;
    }

    void Stop(Player* gm)
    {
        if (Creature* m = Monster(gm)) m->DespawnOrUnsummon();
        for (uint32 low : sScene.bots) if (low) BuddyDismissStandIn(low);
        sScene = Scene();
        sFrames.close();
    }

    class buddies_scenes_world : public WorldScript
    {
    public:
        buddies_scenes_world() : WorldScript("buddies_scenes_world", { WORLDHOOK_ON_UPDATE }) { }

        void OnUpdate(uint32 diff) override
        {
            _since += diff;
            if (_since < PASS_MS || sScene.stage == Stage::NONE) return;
            _since = 0;
            Player* gm = Bot(sScene.gm);
            if (!gm || !gm->IsInWorld()) return;
            uint64 now = GameTime::GetGameTimeMS().count();
            switch (sScene.stage)
            {
                case Stage::BRINGING: if (Bring(gm)) Begin(gm); break;
                case Stage::FIGHTING: Watch(gm, now); break;
                case Stage::BREATH:   if (now - sScene.since >= BREATH_MS) Begin(gm); break;
                default: break;
            }
        }

    private:
        uint32 _since = 0;
    };

    class buddies_scenes_unit : public UnitScript
    {
    public:
        buddies_scenes_unit() : UnitScript("buddies_scenes_unit", true, { UNITHOOK_ON_HEAL }) { }

        uint32 DealDamage(Unit* attacker, Unit* victim, uint32 damage, DamageEffectType ) override
        {
            if (!damage || sScene.stage != Stage::FIGHTING || !attacker || !victim) return damage;
            int by = attacker->IsPlayer() ? SeatOf(attacker->GetGUID().GetCounter()) : -1;
            int on = victim->IsPlayer() ? SeatOf(victim->GetGUID().GetCounter()) : -1;
            bool fromMonster = attacker->GetGUID() == sScene.monster, toMonster = victim->GetGUID() == sScene.monster;
            if (by < 0 && on < 0 && !fromMonster && !toMonster) return damage;
            std::lock_guard<std::mutex> lock(sTallyLock);
            if (by >= 0 && size_t(by) < sScene.tally.size()) sScene.tally[by].dealt += damage;
            if (on >= 0 && size_t(on) < sScene.tally.size()) sScene.tally[on].taken += damage;
            if (fromMonster) sScene.monsterTally.dealt += damage;
            if (toMonster)   sScene.monsterTally.taken += damage;
            return damage;
        }

        void OnHeal(Unit* healer, Unit* , uint32& gain) override
        {
            if (!gain || sScene.stage != Stage::FIGHTING || !healer || !healer->IsPlayer()) return;
            int by = SeatOf(healer->GetGUID().GetCounter());
            if (by < 0) return;
            std::lock_guard<std::mutex> lock(sTallyLock);
            if (size_t(by) < sScene.tally.size()) sScene.tally[by].healed += gain;
        }
    };

    class buddies_scenes_player : public PlayerScript
    {
    public:
        buddies_scenes_player() : PlayerScript("buddies_scenes_player", { PLAYERHOOK_ON_SPELL_CAST }) { }

        void OnPlayerSpellCast(Player* player, Spell* spell, bool ) override
        {
            if (sScene.stage != Stage::FIGHTING || !player || !spell || spell->IsTriggered()) return;
            int seat = SeatOf(player->GetGUID().GetCounter());
            if (seat < 0) return;
            Unit* on = spell->m_targets.GetUnitTarget();
            std::string what = Clean(spell->GetSpellInfo()->SpellName[0]) + ">" + (on ? Clean(on->GetName()) : std::string("-"));
            std::lock_guard<std::mutex> lock(sTallyLock);
            if (size_t(seat) < sScene.tally.size())
                sScene.tally[seat].casts += (sScene.tally[seat].casts.empty() ? "" : ";") + what;
        }
    };

    class buddies_scenes_command : public CommandScript
    {
    public:
        buddies_scenes_command() : CommandScript("buddies_scenes_command") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable commandTable =
            {
                { "buddy scene", HandleScene, SEC_GAMEMASTER, Console::No },
            };
            return commandTable;
        }

        static bool HandleScene(ChatHandler* handler, Optional<std::string> name, Optional<std::string> option)
        {
            Player* gm = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
            if (!gm) return true;
            if (!name)
            {
                if (sScene.stage == Stage::NONE) { handler->SendSysMessage("No scene running. Scenes: duel, party60, party30, party15 (add \"redraw\" to draw the stand-ins again each round)."); return true; }
                handler->PSendSysMessage("Scene {}: round {}, {}; its frames: LogsDir/buddies-scenes/{}-frames.tsv, its rounds: {}.tsv", sScene.kind->name, sScene.round,
                    sScene.stage == Stage::BRINGING ? "bringing the stand-ins" : sScene.stage == Stage::FIGHTING ? "fighting" : "between rounds", sScene.kind->name, sScene.kind->name);
                return true;
            }
            if (*name == "stop")
            {
                if (sScene.stage == Stage::NONE) { handler->SendSysMessage("No scene running."); return true; }
                Stop(gm);
                handler->SendSysMessage("Scene stopped: the stand-ins went back to the pool, the monster is gone.");
                return true;
            }
            Kind const* kind = nullptr;
            for (Kind const& k : KINDS) if (*name == k.name) kind = &k;
            if (!kind) { handler->PSendSysMessage("No scene named {}. Scenes: duel, party60, party30, party15.", *name); return true; }
            if (sScene.stage != Stage::NONE) { handler->PSendSysMessage("Scene {} is running: \".buddy scene stop\" first.", sScene.kind->name); return true; }
            uint32 entry = PickMonster(kind->monsterLevel, kind->monsterRank);
            if (!entry)
            {
                handler->PSendSysMessage("No plain humanoid warrior of level {} and rank {} in this world's creatures: the scene can't be set.", kind->monsterLevel, kind->monsterRank);
                return true;
            }
            sScene = Scene();
            sScene.kind = kind;
            sScene.redraw = option && *option == "redraw";
            sScene.gm = gm->GetGUID().GetCounter();
            sScene.map = gm->GetMapId(); sScene.x = gm->GetPositionX(); sScene.y = gm->GetPositionY(); sScene.z = gm->GetPositionZ(); sScene.o = gm->GetOrientation();
            sScene.bots.assign(kind->seats.size(), 0);
            sScene.monsterEntry = entry;
            sScene.stage = Stage::BRINGING;
            sScene.since = GameTime::GetGameTimeMS().count();
            OpenFrames();
            handler->PSendSysMessage("Scene {}: {} stand-ins at {} against creature {} (level {}{}), {} yards ahead; rounds until \".buddy scene stop\".{}",
                kind->name, kind->seats.size(), kind->botLevel, entry, kind->monsterLevel, kind->boss ? ", counted as a boss" : "", uint32(MONSTER_AHEAD),
                sConfigMgr->GetOption<int32>("Buddies.ForwardPass", 0) == 1 ? "" : " Buddies.ForwardPass is 0: no stand-in fights with the forward pass until it is 1.");
            return true;
        }
    };
}

bool BuddySceneHolds(uint32 guid)
{
    return sScene.stage == Stage::FIGHTING && SeatOf(guid) >= 0;
}
int BuddySceneForwardPass(uint32 guid)
{
    int seat = sScene.stage == Stage::NONE ? -1 : SeatOf(guid);
    return seat < 0 ? -1 : (sScene.kind->seats[seat].forward ? 1 : 0);
}
bool BuddySceneIsBoss(uint64 rawGuid)
{
    return sScene.stage != Stage::NONE && sScene.kind && sScene.kind->boss && sScene.monster.GetRawValue() == rawGuid;
}

void AddSC_buddies_scenes()
{
    new buddies_scenes_world();
    new buddies_scenes_unit();
    new buddies_scenes_player();
    new buddies_scenes_command();
}
