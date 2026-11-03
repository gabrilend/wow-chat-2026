
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

static constexpr uint32 SOLO_LOOK_MS = 500;

struct SoloFight
{
    ObjectGuid      foe;
    BuddySolo::Kind kind        = BuddySolo::KIND_WARRIOR;
    float           foeHealth   = 0.0f;
    float           startHealth = 0.0f;
    float           startPower  = 0.0f;
    uint64          began       = 0;
    bool            spoiled     = false;
};

struct SoloState
{
    BuddySolo::Records records;
    bool               fighting = false;
    SoloFight          fight;
    uint32             sinceLook = 0;
};

static std::mutex sSoloLock;
static std::unordered_map<uint32, SoloState> sSolo;

static int BuddyKindOf(Player* p)
{
    uint32 account = p->GetSession()->GetAccountId();
    if (BuddyIsStandInAccount(account))
        return 2;
    if (BuddyIsCompanionAccount(account))
        return 1;
    return 0;
}

static float FoeDps(Creature* foe)
{
    float lo = foe->GetWeaponDamageRange(BASE_ATTACK, MINDAMAGE);
    float hi = foe->GetWeaponDamageRange(BASE_ATTACK, MAXDAMAGE);
    float speed = foe->GetAttackTime(BASE_ATTACK) / 1000.0f;
    return speed > 0.0f ? (lo + hi) * 0.5f / speed : 0.0f;
}

static void Save(uint32 buddy, BuddySolo::Kind kind, BuddySolo::Fight const& f)
{
    CharacterDatabase.Execute("REPLACE INTO buddy_solo_record (buddy, kind, foe_health, foe_dps, health_lost, mana_spent, seconds, gold_cost, won) "
        "VALUES ({}, {}, {}, {}, {}, {}, {}, {}, UNIX_TIMESTAMP())",
        buddy, uint32(kind), f.foeHealth, f.foeDps, f.healthLost, f.manaSpent, f.seconds, f.goldCost);
}

bool BuddySoloCanTake(Player* bot, Creature* foe, uint32 allies)
{
    BuddySolo::Kind kind;
    if (!BuddySolo::KindOf(foe->GetCreatureTemplate()->unit_class, kind))
        return false;
    std::lock_guard<std::mutex> lock(sSoloLock);
    auto it = sSolo.find(bot->GetGUID().GetCounter());
    if (it == sSolo.end())
        return true;
    return it->second.records.CanTake(kind, float(foe->GetHealth()), FoeDps(foe), allies);
}

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

class buddies_solo_player : public PlayerScript
{
public:
    buddies_solo_player() : PlayerScript("buddies_solo_player",
        { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE }) { }

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
                        continue;
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

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        uint32 low = player->GetGUID().GetCounter();
        std::lock_guard<std::mutex> lock(sSoloLock);
        auto it = sSolo.find(low);
        if (it == sSolo.end() || it->second.records.standIn)
            return;
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
            s.fighting = false;
            return;
        }
        if (foe->IsAlive())
        {
            if (Helped(player, foe) || player->getAttackers().size() > 1)
                s.fight.spoiled = true;
            return;
        }

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

private:
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

void AddSC_buddies_solo()
{
    new buddies_solo_player();
}
