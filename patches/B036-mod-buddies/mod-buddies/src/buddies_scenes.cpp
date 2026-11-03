/*
 * buddies_scenes.cpp - fight scenes: stand-ins against one monster, round
 * after round, every round written down (issue 176a3, test scenes for the
 * fight's forward pass, 625n).
 *
 * For a general audience: to see whether the buddies' new way of fighting
 * (the forward pass) does better than the bot module's own, the same fight
 * is played again and again and each round is written down. The owner,
 * 2026-10-31: "two bots fighting a monster. The monster should be level 45
 * and the bots should be level 40. Then, have one of the bots use the
 * playerbots style combat style, and have the other do the new system."
 * And a party: "one boss monster level 65 and 3 buddy-bots at level 60.
 * They should fight the boss monster, and if any of them are slain then
 * they wait until either the boss dies, or the entire party dies. When the
 * fight ends, they are all reset and it runs again, but any randomization
 * we apply can be re-applied." Then the same at 30 and 35 ("fewer
 * abilities") and at 15 and 20 ("the earliest dungeon experience").
 *
 * ".buddy scene <name> [redraw]" starts one where the game master stands:
 *   duel     two damage stand-ins of one class at 40, against a level-45
 *            monster; the first fights the bot module's way, the second
 *            with the forward pass
 *   party60  a tank, a healer and a damage stand-in at 60, against a
 *            level-65 elite counted as a boss
 *   party30  the same at 30 against 35
 *   party15  the same at 15 against 20
 * ".buddy scene" alone: how it stands; ".buddy scene stop": ends it (the
 * stand-ins go back to the pool, the monster is removed).
 *
 * A round: the stand-ins brought (each kept one reused, as the army does),
 * put in one party, reset (raised if dead, full health and power, cooldowns
 * cleared, out of combat) and placed round the start, each at a random
 * angle; a monster of exactly the scene's level summoned 12 yards ahead (a
 * plain humanoid warrior from the world's own creatures, the lowest entry
 * of the level and rank, made hostile to everyone); it attacks, every
 * stand-in on its threat list. The fallen lie where they fell (the release
 * rule, BuddyReleaseRule, asks BuddySceneHolds) until the monster dies or
 * the whole party has fallen, or ROUND_MOST_MS pass. The randomness is
 * drawn again for the next round: each start angle, and with "redraw" the
 * stand-ins themselves (new classes in the same roles; the duel's two again
 * of one class).
 *
 * What is written (the owner, 2026-10-31: "we're less interested in the
 * result of the fight, and more on the system that creates it - can we
 * create comprehensive logging that shows at each "frame" the exact status
 * of the combatants? We will then use these logs to create a mesh of
 * curves, one chart for each combatant"; nothing is told in game):
 *   LogsDir/buddies-scenes/<scene>-frames.tsv  every PASS_MS of a fight, one
 *       line per combatant (each stand-in and the monster): its health,
 *       power, place, targets, cast, every aura on it, the monster's threat
 *       on it, its running damage and healing, the spells it cast since the
 *       last frame (its choices), and the forward pass's view of it
 *       (BuddyForwardPassFrame); the columns are FRAME_COLUMNS's, then the
 *       forward pass's. One chart per combatant is its lines by `who`
 *       within a round, over `t`.
 *   LogsDir/buddies-scenes/<scene>.tsv  one line per stand-in per round:
 *       how it ended, the damage dealt and taken, the healing, falls.
 * Both are appended to, a line starting with "#" first in a new file says
 * what made it, and each frame is flushed, so the file can be read while
 * the scene runs (a live viewer, later).
 *
 * The forward pass: on for every stand-in of a party scene; in the duel on
 * for the second only (BuddySceneForwardPass). The scene's monster counts as
 * a boss to it in the party scenes (BuddySceneIsBoss). Buddies.ForwardPass
 * must be 1 for it to run at all: the command says so when it isn't.
 *
 * World thread only: the command and the pass both run there; the damage
 * and heal hooks (map threads) touch only the tallies, behind a lock.
 */

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

// the forward pass's view of one character, for the frames (buddies_forward_pass.cpp)
std::string BuddyForwardPassFrameColumns();
std::string BuddyForwardPassFrame(Player* who);

namespace
{
    // {{{ the numbers
    // PASS_MS: how often the scene is looked after. ROUND_MOST_MS: a round
    // ends undecided after this long (a monster neither side can bring
    // down). MONSTER_AHEAD: yards from the start the monster appears.
    // CIRCLE: yards round the start the stand-ins are placed. BREATH_MS: a
    // pause between rounds, so a round's end is seen before the next.
    constexpr uint32 PASS_MS       = 500;
    constexpr uint64 ROUND_MOST_MS = 600000;
    constexpr float  MONSTER_AHEAD = 12.0f;
    constexpr float  CIRCLE        = 4.0f;
    constexpr uint64 BREATH_MS     = 5000;
    // }}}

    // {{{ the scenes
    // A seat: the role a stand-in is brought for (0 damage, 1 tank, 2
    // healer) and whether it fights with the forward pass. `sameClassAs`:
    // the seat whose class it takes (-1: drawn).
    struct Seat { uint8 role; bool forward; int sameClassAs; };
    struct Kind
    {
        char const* name;
        uint8 botLevel, monsterLevel, monsterRank;   // rank: 0 normal, 1 elite
        bool boss;                                   // counted as a boss by the forward pass
        std::vector<Seat> seats;
    };
    std::vector<Kind> const KINDS = {
        { "duel",    40, 45, 0, false, { { 0, false, -1 }, { 0, true, 0 } } },
        { "party60", 60, 65, 1, true,  { { 1, true, -1 }, { 2, true, -1 }, { 0, true, -1 } } },
        { "party30", 30, 35, 1, true,  { { 1, true, -1 }, { 2, true, -1 }, { 0, true, -1 } } },
        { "party15", 15, 20, 1, true,  { { 1, true, -1 }, { 2, true, -1 }, { 0, true, -1 } } },
    };
    // }}}

    // {{{ the running scene
    // Its stages: bringing the stand-ins, then rounds (a fight, then a
    // breath); one scene at a time on the server.
    enum class Stage { NONE, BRINGING, FIGHTING, BREATH };
    // casts: the spells it cast since the last frame, "name>target;..."
    // (written by the cast hook, emptied by each frame)
    struct Tally { double dealt = 0, taken = 0, healed = 0; bool fell = false; std::string casts; };
    struct Scene
    {
        Kind const* kind = nullptr;
        bool redraw = false;
        Stage stage = Stage::NONE;
        uint32 gm = 0;                               // the game master's character number
        uint32 map = 0; float x = 0, y = 0, z = 0, o = 0;
        std::vector<uint32> bots;                    // per seat, the stand-in's character number (0: not yet)
        uint8 drawnClass = 0;                        // the duel's class, once its first stand-in is in
        ObjectGuid monster;
        uint32 monsterEntry = 0;
        uint32 round = 0;
        uint64 since = 0;                            // when the stage began
        std::vector<Tally> tally;                    // per seat, this round
        Tally monsterTally;                          // the monster's, this round
        uint32 frame = 0;                            // frames written this round
    };
    Scene sScene;
    std::ofstream sFrames;                           // the frames file, open while a scene runs
    std::mutex sTallyLock;                           // the tallies: written from the map threads' hooks

    Player* Bot(uint32 low) { return low ? ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(low)) : nullptr; }
    int SeatOf(uint32 low)
    {
        for (size_t i = 0; i < sScene.bots.size(); ++i) if (sScene.bots[i] == low) return int(i);
        return -1;
    }
    // }}}

    // {{{ the monster
    // The scene's monster: the lowest-entry plain humanoid warrior of exactly
    // the level and rank (no script of its own, attackable), so every round
    // of a scene meets the same one. 0 when the world has none.
    uint32 PickMonster(uint8 level, uint8 rank)
    {
        QueryResult r = WorldDatabase.Query(
            "SELECT entry FROM creature_template WHERE minlevel = {} AND maxlevel = {} AND `rank` = {} AND type = 7 AND unit_class = 1 "
            "AND ScriptName = '' AND AIName = '' AND npcflag = 0 AND (unit_flags & 33555202) = 0 ORDER BY entry LIMIT 1",
            uint32(level), uint32(level), uint32(rank));
        return r ? (*r)[0].Get<uint32>() : 0;
    }
    Creature* Monster(Player* near) { return near ? ObjectAccessor::GetCreature(*near, sScene.monster) : nullptr; }
    // }}}

    // {{{ the record
    // One line per stand-in per round, in the server's logs folder.
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
    // }}}

    // {{{ the frames
    // FRAME_COLUMNS, each frame's line per combatant:
    //   when          the server's clock (unix seconds)
    //   round, frame  the round, and the frame within it
    //   t             seconds since the round began
    //   who, side     the combatant's name; stand-in or monster
    //   seat          its seat in the scene (- the monster)
    //   class, role   its class (the game's number); role 0 damage, 1 tank,
    //                 2 healer (- the monster)
    //   forward       1 fights with the forward pass, 0 the bot module's way
    //   alive, combat 1 or 0
    //   health, max-health, power-kind (the game's: 0 mana, 1 rage, 3
    //                 energy, 6 runic power), power, max-power
    //   x, y, z, facing, moving (1 or 0)
    //   distance      yards to the monster (the monster: to whom it attacks)
    //   target        whom it has selected; attacking: whom it swings at
    //   casting       the spell being cast or channelled now, "id:name"; cast-left
    //                 its milliseconds left
    //   auras         every aura on it, "id:name:stacks:seconds-left:caster:+|-"
    //                 joined by ";" (seconds -1: no end; + helpful, - harmful)
    //   threat        the monster's threat on it (the monster: -)
    //   dealt, taken, healed  running totals this round
    //   casts         the spells it cast since the last frame, "name>target;"
    //                 (its choices; procs and other triggered casts left out;
    //                 the monster: -)
    char const* const FRAME_COLUMNS =
        "when\tround\tframe\tt\twho\tside\tseat\tclass\trole\tforward\talive\tcombat\thealth\tmax-health\tpower-kind\tpower\tmax-power\t"
        "x\ty\tz\tfacing\tmoving\tdistance\ttarget\tattacking\tcasting\tcast-left\tauras\tthreat\tdealt\ttaken\thealed\tcasts";

    // a name or text safe inside a field (no tabs, line ends, or the
    // separators ";" ":" ">" the lists use)
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

    // {{{ OpenFrames
    // The frames file for the scene, appended to; its first lines (a new
    // file) say what made it and name the columns.
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
    // }}}

    // {{{ Frame
    // One frame: a line per combatant, the stand-ins in seat order, then the
    // monster.
    void Frame(Creature* monster, uint64 now)
    {
        if (!sFrames) return;
        ++sScene.frame;
        std::string head = std::to_string(GameTime::GetGameTime().count()) + "\t" + std::to_string(sScene.round) + "\t" +
                           std::to_string(sScene.frame) + "\t" + Num((now - sScene.since) / 1000.0, 1) + "\t";
        // a combatant's own columns, from `name` on (the side's and the
        // tally's parts given by the caller)
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
            // `side` stands for the columns side..forward; alive.. follow in state()
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
    // }}}
    // }}}

    // {{{ Tell
    // A trouble said to the game master (a stand-in not brought, no monster):
    // what can't be read from the files. The rounds themselves are not told.
    void Tell(std::string const& text)
    {
        if (Player* gm = Bot(sScene.gm))
            ChatHandler(gm->GetSession()).SendSysMessage(text);
    }
    // }}}

    // {{{ Bring
    // Each empty seat's stand-in asked for (role, the scene's level, the
    // duel's second of the first's class); true when every seat's is in the
    // world with its first moments done.
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
                    if (!sScene.drawnClass) { all = false; continue; }      // its class isn't known yet
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
    // }}}

    // {{{ Party
    // The stand-ins in one party, the first leading.
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
    // }}}

    // {{{ Begin
    // A round: everyone reset and placed, a fresh monster, the fight on.
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
            float a = float(rand_norm()) * 6.2831853f;                    // drawn again each round
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
        m->SetFaction(14);                                             // hostile to everyone
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
    // }}}

    // {{{ Watch
    // A fight in progress: its end, when there is one.
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
        Frame(m, now);                                                 // the last frame of a round too
        uint64 ms = now - sScene.since;
        char const* how = monsterDown ? "monster-down" : partyDown ? "party-down" : ms >= ROUND_MOST_MS ? "undecided" : nullptr;
        if (!how) return;
        Write(how, ms, m);
        if (m && !m->isDead()) m->DespawnOrUnsummon();
        // the randomness drawn again: with "redraw", the stand-ins themselves
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
    // }}}

    // {{{ Stop
    void Stop(Player* gm)
    {
        if (Creature* m = Monster(gm)) m->DespawnOrUnsummon();
        for (uint32 low : sScene.bots) if (low) BuddyDismissStandIn(low);
        sScene = Scene();
        sFrames.close();
    }
    // }}}

    // {{{ buddies_scenes_world
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
            if (!gm || !gm->IsInWorld()) return;                       // the game master away: the scene waits
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
    // }}}

    // {{{ buddies_scenes_unit
    // The tallies: damage dealt and taken, healing done, by the scene's
    // stand-ins in a fight.
    class buddies_scenes_unit : public UnitScript
    {
    public:
        buddies_scenes_unit() : UnitScript("buddies_scenes_unit", true, { UNITHOOK_ON_HEAL }) { }

        uint32 DealDamage(Unit* attacker, Unit* victim, uint32 damage, DamageEffectType /*type*/) override
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

        void OnHeal(Unit* healer, Unit* /*receiver*/, uint32& gain) override
        {
            if (!gain || sScene.stage != Stage::FIGHTING || !healer || !healer->IsPlayer()) return;
            int by = SeatOf(healer->GetGUID().GetCounter());
            if (by < 0) return;
            std::lock_guard<std::mutex> lock(sTallyLock);
            if (size_t(by) < sScene.tally.size()) sScene.tally[by].healed += gain;
        }
    };
    // }}}

    // {{{ buddies_scenes_player
    // The choices: each spell a stand-in casts in a fight (when it goes off),
    // kept for the next frame. Triggered casts (procs, a spell's own
    // follow-ups) are left out: they aren't chosen.
    class buddies_scenes_player : public PlayerScript
    {
    public:
        buddies_scenes_player() : PlayerScript("buddies_scenes_player", { PLAYERHOOK_ON_SPELL_CAST }) { }

        void OnPlayerSpellCast(Player* player, Spell* spell, bool /*skipCheck*/) override
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
    // }}}

    // {{{ .buddy scene
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
    // }}}
}

// {{{ the scene, asked by the rest of the module
// A stand-in of the running scene, dead in a fight: it holds (the release
// rule, buddies_release.cpp), until the round ends.
bool BuddySceneHolds(uint32 guid)
{
    return sScene.stage == Stage::FIGHTING && SeatOf(guid) >= 0;
}
// Whether a character fights with the forward pass by the scene's say:
// -1 not the scene's (the switch decides), 0 no, 1 yes.
int BuddySceneForwardPass(uint32 guid)
{
    int seat = sScene.stage == Stage::NONE ? -1 : SeatOf(guid);
    return seat < 0 ? -1 : (sScene.kind->seats[seat].forward ? 1 : 0);
}
// Whether a creature is the running scene's monster, counted as a boss.
bool BuddySceneIsBoss(uint64 rawGuid)
{
    return sScene.stage != Stage::NONE && sScene.kind && sScene.kind->boss && sScene.monster.GetRawValue() == rawGuid;
}
// }}}

// {{{ AddSC_buddies_scenes
void AddSC_buddies_scenes()
{
    new buddies_scenes_world();
    new buddies_scenes_unit();
    new buddies_scenes_player();
    new buddies_scenes_command();
}
// }}}
