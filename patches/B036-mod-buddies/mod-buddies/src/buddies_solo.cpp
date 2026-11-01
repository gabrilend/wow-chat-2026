/*
 * buddies_solo.cpp - noting the fights a buddy wins alone (issue 623,
 * question 7), and keeping them as its solo record.
 *
 * For a general audience: the owner, 2026-10-30: "whenever a buddy-bot
 * defeats a foe on their own entirely with no help at all, we record the
 * conditions that the fight had". A buddy's fight is watched twice a
 * second while it lasts: when it began, the foe's health, the buddy's own
 * health and mana are noted; if anyone else joins in (anyone but the buddy
 * and its pet on the foe's threat list: a healer's heals, a friend's blow)
 * or a second foe attacks it, the fight no longer counts. When the foe
 * dies and the buddy is still standing, what it cost is worked out and
 * handed to the record (roam/buddy_solo_core.h), which keeps it only when
 * it is more in every number than the one it holds. Kept records go to the
 * buddy_solo_record table, read back at login.
 *
 * What is measured, and how:
 *   foe health   - the foe's health when the buddy's fight with it began
 *   foe dps      - the health the buddy lost over the fight's seconds (its
 *                  own heals during the fight make this lower than the
 *                  blows were: a buddy that heals itself counts the foe as
 *                  gentler, which is the cost as it felt it)
 *   health lost  - its health at the start minus at the end, at least 0
 *   mana spent   - the same for its resource (mana, rage, energy), at least 0
 *   seconds      - from the start to the foe's death
 *   gold cost    - 0 for now: buddies use no potions or other paid
 *                  consumables in a fight yet (their meals come after it)
 *
 * Buffs before the fight leave it solo ("buffs don't count ... But buffs
 * are fine"): only who is on the foe's threat list during the fight is
 * looked at, and a buff cast before it began puts no one there.
 */

#include "buddies.h"
#include "buddies_solo.h"
#include "roam/buddy_solo_core.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ThreatManager.h"
#include <mutex>
#include <unordered_map>

static constexpr uint32 SOLO_LOOK_MS = 500;            // how often a buddy's fight is looked at

// {{{ the watched fight and the records
// SoloFight: the fight under way, what it began with; `spoiled` once
// anyone helped or a second foe joined (it then no longer counts).
struct SoloFight
{
    ObjectGuid      foe;
    BuddySolo::Kind kind        = BuddySolo::KIND_WARRIOR;
    float           foeHealth   = 0.0f;
    float           startHealth = 0.0f;
    float           startPower  = 0.0f;
    uint64          began       = 0;                   // game-time ms
    bool            spoiled     = false;
};

struct SoloState
{
    BuddySolo::Records records;
    bool               fighting = false;
    SoloFight          fight;
    uint32             sinceLook = 0;                  // ms since the last look
};

static std::mutex sSoloLock;
static std::unordered_map<uint32, SoloState> sSolo;    // buddy (low guid) -> its records and fight; under sSoloLock
// }}}

// {{{ BuddyKindOf
// Which kind of character `p` is, for this file: 1 a buddy, 2 a stand-in,
// 0 anyone else (owners, alt bots, random bots: no record kept).
static int BuddyKindOf(Player* p)
{
    uint32 account = p->GetSession()->GetAccountId();
    if (BuddyIsStandInAccount(account))
        return 2;
    if (BuddyIsCompanionAccount(account))
        return 1;
    return 0;
}
// }}}

// {{{ FoeDps
// A foe's damage per second from the game's data: its main weapon's damage
// (the middle of its range) over its attack speed. A foe that hits with
// spells deals more than this; the record compares like with like, as the
// record's own foe dps is what the buddy felt.
static float FoeDps(Creature* foe)
{
    float lo = foe->GetWeaponDamageRange(BASE_ATTACK, MINDAMAGE);
    float hi = foe->GetWeaponDamageRange(BASE_ATTACK, MAXDAMAGE);
    float speed = foe->GetAttackTime(BASE_ATTACK) / 1000.0f;
    return speed > 0.0f ? (lo + hi) * 0.5f / speed : 0.0f;
}
// }}}

// {{{ Save
static void Save(uint32 buddy, BuddySolo::Kind kind, BuddySolo::Fight const& f)
{
    CharacterDatabase.Execute("REPLACE INTO buddy_solo_record (buddy, kind, foe_health, foe_dps, health_lost, mana_spent, seconds, gold_cost, won) "
        "VALUES ({}, {}, {}, {}, {}, {}, {}, {}, UNIX_TIMESTAMP())",
        buddy, uint32(kind), f.foeHealth, f.foeDps, f.healthLost, f.manaSpent, f.seconds, f.goldCost);
}
// }}}

// {{{ BuddySoloCanTake
bool BuddySoloCanTake(Player* bot, Creature* foe, uint32 allies)
{
    BuddySolo::Kind kind;
    if (!BuddySolo::KindOf(foe->GetCreatureTemplate()->unit_class, kind))
        return false;                                  // a creature class outside the four: no record speaks for it
    std::lock_guard<std::mutex> lock(sSoloLock);
    auto it = sSolo.find(bot->GetGUID().GetCounter());
    if (it == sSolo.end())
        return true;                                   // not a buddy or stand-in (or not logged in): no fear to judge
    return it->second.records.CanTake(kind, float(foe->GetHealth()), FoeDps(foe), allies);
}
// }}}

// {{{ BuddySoloForget
void BuddySoloForget(uint32 buddyGuid)
{
    {
        std::lock_guard<std::mutex> lock(sSoloLock);
        auto it = sSolo.find(buddyGuid);
        if (it != sSolo.end())
            it->second.records.Forget();
    }
    CharacterDatabase.Execute("DELETE FROM buddy_solo_record WHERE buddy = {}", buddyGuid);
}
// }}}

// {{{ buddies_solo_player
class buddies_solo_player : public PlayerScript
{
public:
    buddies_solo_player() : PlayerScript("buddies_solo_player",
        { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE }) { }

    // A buddy's records are read back; a stand-in gets an empty set that
    // never fills ("stand-ins should never remember this stuff - they
    // always are brave and vigilant").
    void OnPlayerLogin(Player* player) override
    {
        int who = BuddyKindOf(player);
        if (!who)
            return;
        SoloState s;
        s.records.standIn = who == 2;
        if (who == 1)
            if (QueryResult r = CharacterDatabase.Query("SELECT kind, foe_health, foe_dps, health_lost, mana_spent, seconds, gold_cost "
                "FROM buddy_solo_record WHERE buddy = {}", player->GetGUID().GetCounter()))
                do
                {
                    Field* f = r->Fetch();
                    uint8 k = f[0].Get<uint8>();
                    if (k >= BuddySolo::KIND_COUNT)
                        continue;                      // a kind this build doesn't know: left in the table, unread
                    s.records.has[k]  = true;
                    s.records.best[k] = { f[1].Get<float>(), f[2].Get<float>(), f[3].Get<float>(),
                                          f[4].Get<float>(), f[5].Get<float>(), f[6].Get<float>() };
                } while (r->NextRow());
        std::lock_guard<std::mutex> lock(sSoloLock);
        sSolo[player->GetGUID().GetCounter()] = s;
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(sSoloLock);
        sSolo.erase(player->GetGUID().GetCounter());
    }

    // {{{ OnPlayerUpdate
    // Twice a second for a buddy, one of these:
    //   no fight watched, in combat with a creature of a known kind that
    //     only it is fighting                   - the fight is watched from now
    //   watching, the buddy died                - the fight is dropped (lost)
    //   watching, the foe gone or out of combat
    //     alive (it ran home)                   - dropped (not a win)
    //   watching, the foe dead, never helped    - a solo win: handed to the record,
    //                                             saved when it became the record
    //   watching, the foe fighting on           - anyone else on its threat list
    //                                             (but the buddy's pet), or a
    //                                             second foe on the buddy: spoiled
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        uint32 low = player->GetGUID().GetCounter();
        std::lock_guard<std::mutex> lock(sSoloLock);
        auto it = sSolo.find(low);
        if (it == sSolo.end() || it->second.records.standIn)
            return;                                    // not a buddy (owners, other bots), or a stand-in: nothing kept
        SoloState& s = it->second;
        s.sinceLook += diff;
        if (s.sinceLook < SOLO_LOOK_MS)
            return;
        s.sinceLook = 0;
        uint64 now = GameTime::GetGameTimeMS().count();

        if (!s.fighting)
        {
            Creature* foe = player->GetVictim() ? player->GetVictim()->ToCreature() : nullptr;
            BuddySolo::Kind kind;
            if (!player->IsInCombat() || !foe || !foe->IsAlive()
                || !BuddySolo::KindOf(foe->GetCreatureTemplate()->unit_class, kind))
                return;
            s.fighting = true;
            s.fight = SoloFight();
            s.fight.foe         = foe->GetGUID();
            s.fight.kind        = kind;
            s.fight.foeHealth   = float(foe->GetHealth());
            s.fight.startHealth = float(player->GetHealth());
            s.fight.startPower  = float(player->GetPower(player->getPowerType()));
            s.fight.began       = now;
            s.fight.spoiled     = Helped(player, foe);
            return;
        }

        Creature* foe = ObjectAccessor::GetCreature(*player, s.fight.foe);
        if (!player->IsAlive() || !foe || (foe->IsAlive() && !foe->IsInCombat()))
        {
            s.fighting = false;                        // lost, or the foe vanished or ran home: no record
            return;
        }
        if (foe->IsAlive())
        {
            if (Helped(player, foe) || player->getAttackers().size() > 1)
                s.fight.spoiled = true;
            return;
        }

        // the foe is dead
        s.fighting = false;
        if (s.fight.spoiled)
            return;
        BuddySolo::Fight f;
        f.seconds    = std::max(0.5f, (now - s.fight.began) / 1000.0f);
        f.foeHealth  = s.fight.foeHealth;
        f.healthLost = std::max(0.0f, s.fight.startHealth - float(player->GetHealth()));
        f.manaSpent  = std::max(0.0f, s.fight.startPower - float(player->GetPower(player->getPowerType())));
        f.foeDps     = f.healthLost / f.seconds;
        f.goldCost   = 0.0f;
        if (s.records.Won(s.fight.kind, f))
        {
            Save(low, s.fight.kind, f);
            LOG_DEBUG("module", "buddies: {} set a solo record against kind {}: foe health {:.0f}, {:.1f} dps, lost {:.0f}, spent {:.0f}, {:.1f} s",
                player->GetName(), uint32(s.fight.kind), f.foeHealth, f.foeDps, f.healthLost, f.manaSpent, f.seconds);
        }
    }
    // }}}

private:
    // Whether anyone but the buddy and its own pets or guardians is on the
    // foe's threat list: someone struck it or healed the buddy.
    static bool Helped(Player* bot, Creature* foe)
    {
        for (ThreatReference const* ref : foe->GetThreatMgr().GetSortedThreatList())
        {
            Unit* who = ref->GetVictim();
            if (!who || who == bot || who->GetCharmerOrOwnerGUID() == bot->GetGUID())
                continue;
            return true;
        }
        return false;
    }
};
// }}}

void AddSC_buddies_solo()
{
    new buddies_solo_player();
}
