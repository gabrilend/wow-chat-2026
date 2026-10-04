/*
 * buddies_spells.cpp - what buddies learn, and when (issue 617n; the rules
 * in plain words are in buddies_spells.h).
 *
 * A trainer's lesson is either a spell added to the spell book or a
 * "teach" spell the trainer casts, whose effect adds the real one (the
 * server's TeachSpell does the casting). Away from a trainer, and before
 * a new buddy is in the world, nothing may be cast, so a teach spell's
 * effects are read and the spells they add are added directly (LearnOne).
 * The quest list holds the same mix, and is read the same way.
 */

#include "buddies.h"
#include "buddies_spells.h"
#include "buddies_quest_spells.h"
#include "Creature.h"
#include "DBCStores.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "Trainer.h"
#include "WorldSession.h"
#include <algorithm>
#include <mutex>
#include <vector>

// {{{ tuning
static constexpr uint32 MAX_LESSONS    = 400;   // a trainer visit teaches at most this many (a guard, never reached)
static constexpr uint8  PET_FROM_LEVEL = 10;    // a hunter can first tame at this level
// }}}

// {{{ LearnOne
// Add a spell the way learning it would: a teach spell's taught spells, or
// the spell itself. Returns how many were new.
static uint32 LearnOne(Player* bot, uint32 spellId)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (!info)
        return 0;
    uint32 learned = 0;
    bool teaches = false;
    for (SpellEffectInfo const& eff : info->GetEffects())
        if (eff.IsEffect(SPELL_EFFECT_LEARN_SPELL) && eff.TriggerSpell)
        {
            teaches = true;
            if (!bot->HasSpell(eff.TriggerSpell))
            {
                bot->learnSpell(eff.TriggerSpell, false);
                ++learned;
            }
        }
    if (!teaches && !bot->HasSpell(spellId))
    {
        bot->learnSpell(spellId, false);
        ++learned;
    }
    return learned;
}
// }}}

// {{{ the quest spells
// Whether a spell (or what it teaches) belongs to this class and race by
// the game's own skill tables: a quest list row for a spell the game no
// longer gives the class (a priest's pre-3.0 racial spells, a quest's
// bomb) has no such entry and is passed over.
static bool ClassSkill(uint32 spellId, Player const* bot)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (!info)
        return false;
    std::vector<uint32> ids { spellId };
    for (SpellEffectInfo const& eff : info->GetEffects())
        if (eff.IsEffect(SPELL_EFFECT_LEARN_SPELL) && eff.TriggerSpell)
            ids.push_back(eff.TriggerSpell);
    for (uint32 id : ids)
    {
        SkillLineAbilityMapBounds bounds = sSpellMgr->GetSkillLineAbilityMapBounds(id);
        for (auto it = bounds.first; it != bounds.second; ++it)
            if ((!it->second->ClassMask || (it->second->ClassMask & bot->getClassMask())) &&
                (!it->second->RaceMask  || (it->second->RaceMask  & bot->getRaceMask())))
                return true;
    }
    return false;
}

static uint32 LearnQuestSpells(Player* bot)
{
    uint32 learned = 0;
    for (BuddyQuestSpell const& q : sBuddyQuestSpells)
    {
        if (q.cls != bot->getClass() || q.level > bot->GetLevel())
            continue;
        if (q.races && !(q.races & bot->getRaceMask()))
            continue;
        if (!ClassSkill(q.spell, bot))
            continue;
        learned += LearnOne(bot, q.spell);
    }
    return learned;
}
// }}}

// {{{ BuddyTrainAtTrainer
uint32 BuddyTrainAtTrainer(Player* bot, Creature* npc)
{
    Trainer::Trainer* trainer = sObjectMgr->GetTrainer(npc->GetEntry());
    if (!trainer || trainer->GetTrainerType() != Trainer::Type::Class || !trainer->IsTrainerValidForPlayer(bot))
        return 0;
    float discount = bot->GetReputationPriceDiscount(npc);
    uint32 learned = 0;
    // one lesson at a time, the cheapest of what it can learn now: a rank
    // learned may open the next rank, so the list is looked at again
    // after each (equal costs: the lower level first, then the trainer's order)
    for (uint32 n = 0; n < MAX_LESSONS; ++n)
    {
        std::vector<Trainer::Spell const*> can;
        for (Trainer::Spell const& sp : trainer->GetSpells())
            if (trainer->CanTeachSpell(bot, &sp))
                can.push_back(&sp);
        if (can.empty())
            break;
        std::stable_sort(can.begin(), can.end(), [](Trainer::Spell const* a, Trainer::Spell const* b) {
            return a->MoneyCost != b->MoneyCost ? a->MoneyCost < b->MoneyCost : a->ReqLevel < b->ReqLevel;
        });
        Trainer::Spell const* next = can.front();
        int32 cost = int32(next->MoneyCost * discount);
        if (!bot->HasEnoughMoney(cost))
        {
            LOG_DEBUG("module", "mod-buddies: buddy {} stopped training at {}: the cheapest lesson left (spell {}) costs {} "
                "copper, it has {}", bot->GetName(), npc->GetName(), next->SpellId, cost, bot->GetMoney());
            BuddyTrace(bot, "town: training ended, the cheapest lesson left costs {} copper and it has {}", cost, bot->GetMoney());
            break;
        }
        uint32 before = bot->GetMoney();
        trainer->TeachSpell(npc, bot, next->SpellId);
        if (bot->GetMoney() == before && cost > 0)
            break;                                     // the server refused it after all: stop rather than loop
        ++learned;
    }
    uint32 quest = LearnQuestSpells(bot);
    BuddyTrace(bot, "town: trained at {}: {} lessons bought, {} quest spells added", npc->GetName(), learned, quest);
    return learned + quest;
}
// }}}

// {{{ BuddyLearnEverything
// Every class trainer of the world, by creature entry, found once.
static std::once_flag sTrainersFound;
static std::vector<uint32> sClassTrainers;

uint32 BuddyLearnEverything(Player* bot)
{
    std::call_once(sTrainersFound, [] {
        for (auto const& kv : *sObjectMgr->GetCreatureTemplates())
            if (Trainer::Trainer* t = sObjectMgr->GetTrainer(kv.first))
                if (t->GetTrainerType() == Trainer::Type::Class)
                    sClassTrainers.push_back(kv.first);
    });
    // the lessons of every trainer valid for this buddy (class and race),
    // taught pass after pass until a pass adds nothing (each rank opens the next)
    std::vector<Trainer::Trainer*> mine;
    for (uint32 entry : sClassTrainers)
        if (Trainer::Trainer* t = sObjectMgr->GetTrainer(entry))
            if (t->IsTrainerValidForPlayer(bot))
                mine.push_back(t);
    if (mine.empty())
    {
        LOG_ERROR("module", "mod-buddies: no class trainer in the world teaches buddy {} (class {}, race {}); it starts with only "
            "its quest spells", bot->GetName(), bot->getClass(), bot->getRace());
        return LearnQuestSpells(bot);
    }
    uint32 learned = 0;
    for (bool more = true; more; )
    {
        more = false;
        for (Trainer::Trainer* t : mine)
            for (Trainer::Spell const& sp : t->GetSpells())
                if (t->CanTeachSpell(bot, &sp))
                {
                    uint32 n = LearnOne(bot, sp.SpellId);
                    learned += n;
                    more = more || n > 0;
                }
    }
    return learned + LearnQuestSpells(bot);
}
// }}}

// {{{ BuddyForgetLessons
// The spells learning `spellId` adds (LearnOne's reading of it).
static std::vector<uint32> Taught(uint32 spellId)
{
    std::vector<uint32> ids;
    if (SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId))
        for (SpellEffectInfo const& eff : info->GetEffects())
            if (eff.IsEffect(SPELL_EFFECT_LEARN_SPELL) && eff.TriggerSpell)
                ids.push_back(eff.TriggerSpell);
    if (ids.empty())
        ids.push_back(spellId);
    return ids;
}

uint32 BuddyForgetLessons(Player* bot)
{
    std::call_once(sTrainersFound, [] {
        for (auto const& kv : *sObjectMgr->GetCreatureTemplates())
            if (Trainer::Trainer* t = sObjectMgr->GetTrainer(kv.first))
                if (t->GetTrainerType() == Trainer::Type::Class)
                    sClassTrainers.push_back(kv.first);
    });
    std::vector<uint32> lessons;
    for (uint32 entry : sClassTrainers)
        if (Trainer::Trainer* t = sObjectMgr->GetTrainer(entry))
            if (t->IsTrainerValidForPlayer(bot))
                for (Trainer::Spell const& sp : t->GetSpells())
                    for (uint32 id : Taught(sp.SpellId))
                        lessons.push_back(id);
    for (BuddyQuestSpell const& q : sBuddyQuestSpells)
        if (q.cls == bot->getClass())
            for (uint32 id : Taught(q.spell))
                lessons.push_back(id);
    uint32 removed = 0;
    for (uint32 id : lessons)
        if (bot->HasSpell(id))
        {
            // removing a rank also removes the ranks above it (the server's own rule)
            bot->removeSpell(id, SPEC_MASK_ALL, false);
            ++removed;
        }
    return removed;
}
// }}}

// {{{ the hunter's pet
// A random beast a hunter of this level could tame, made its current pet
// at once (the bot module's own way of making one, PlayerbotFactory::
// InitPet). Any pet it had is let go first.
static void GivePet(Player* bot)
{
    std::vector<uint32> ids;
    for (auto const& kv : *sObjectMgr->GetCreatureTemplates())
        if (kv.second.IsTameable(bot->CanTameExoticPets()) && kv.second.minlevel <= bot->GetLevel() && kv.second.Name.size() <= 21)
            ids.push_back(kv.first);
    if (ids.empty())
    {
        LOG_ERROR("module", "mod-buddies: no beast a level {} hunter could tame; buddy {} has no pet", bot->GetLevel(), bot->GetName());
        return;
    }
    if (bot->GetPet() || (bot->GetPetStable() && bot->GetPetStable()->CurrentPet))
    {
        bot->RemovePet(nullptr, PET_SAVE_AS_DELETED);
        if (bot->GetPetStable())
            bot->GetPetStable()->CurrentPet.reset();
    }
    uint32 entry = ids[urand(0, uint32(ids.size()) - 1)];
    Pet* pet = bot->CreateTamedPetFrom(entry, 0);
    if (!pet)
    {
        LOG_ERROR("module", "mod-buddies: the server would not make creature {} buddy {}'s pet", entry, bot->GetName());
        return;
    }
    pet->SetUInt32Value(UNIT_FIELD_LEVEL, bot->GetLevel());
    pet->GetMap()->AddToMap(pet->ToCreature());
    bot->SetMinion(pet, true);
    pet->InitTalentForLevel();
    pet->InitStatsForLevel(bot->GetLevel());
    pet->SetPower(POWER_HAPPINESS, pet->GetMaxPower(POWER_HAPPINESS));
    pet->SetHealth(pet->GetMaxHealth());
    pet->SavePetToDB(PET_SAVE_AS_CURRENT);
    bot->PetSpellInitialize();
    LOG_INFO("module", "mod-buddies: buddy {} has a new pet, {} (creature {})", bot->GetName(), pet->GetName(), entry);
}

static bool IsBuddyHunter(Player* p)
{
    return BuddiesEnabled() && p->getClass() == CLASS_HUNTER && p->GetLevel() >= PET_FROM_LEVEL &&
           p->GetSession() && BuddyIsCompanionAccount(p->GetSession()->GetAccountId());
}

class buddies_spells_player : public PlayerScript
{
public:
    buddies_spells_player() : PlayerScript("buddies_spells_player", { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_TALENTS_RESET }) { }

    // a hunter buddy without a pet (made at 10 or more, or reaching 10
    // offline) gets one when it comes into the world
    void OnPlayerLogin(Player* player) override
    {
        if (IsBuddyHunter(player) && !player->GetPet() && !(player->GetPetStable() && player->GetPetStable()->CurrentPet))
            GivePet(player);
    }

    // its talents reset (its owner respecced: buddy-talents.lua resets the
    // buddies'): a new pet, at once
    void OnPlayerTalentsReset(Player* player, bool /*noCost*/) override
    {
        if (IsBuddyHunter(player) && player->IsInWorld())
            GivePet(player);
    }
};

void AddSC_buddies_spells()
{
    new buddies_spells_player();
}
// }}}
