
#include "buddies.h"
#include "buddies_spells.h"
#include "buddies_quest_spells.h"
#include "Containers.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ObjectAccessor.h"
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
#include <set>
#include <string>
#include <vector>

static constexpr uint32 MAX_LESSONS    = 400;
static constexpr uint8  PET_FROM_LEVEL = 10;

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

uint32 BuddyTrainAtTrainer(Player* bot, Creature* npc)
{
    Trainer::Trainer* trainer = sObjectMgr->GetTrainer(npc->GetEntry());
    if (!trainer || trainer->GetTrainerType() != Trainer::Type::Class || !trainer->IsTrainerValidForPlayer(bot))
        return 0;
    float discount = bot->GetReputationPriceDiscount(npc);
    uint32 quest = LearnQuestSpells(bot);
    uint32 learned = 0;
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
            break;
        ++learned;
    }
    BuddyTrace(bot, "town: trained at {}: {} lessons bought, {} quest spells added", npc->GetName(), learned, quest);
    return learned + quest;
}

struct WeaponLesson { uint32 trainerEntry; uint32 spellId; uint32 skill; };
static std::once_flag sWeaponLessonsFound;
static std::vector<WeaponLesson> sWeaponLessons;
static std::set<uint32> sWeaponKinds;

static uint32 WeaponKindTaught(uint32 spellId)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (!info)
        return 0;
    std::vector<uint32> ids { spellId };
    for (SpellEffectInfo const& eff : info->GetEffects())
        if (eff.IsEffect(SPELL_EFFECT_LEARN_SPELL) && eff.TriggerSpell)
            ids.push_back(eff.TriggerSpell);
    for (uint32 id : ids)
    {
        SkillLineAbilityMapBounds bounds = sSpellMgr->GetSkillLineAbilityMapBounds(id);
        for (auto it = bounds.first; it != bounds.second; ++it)
            if (sWeaponKinds.count(it->second->SkillLine))
                return it->second->SkillLine;
    }
    return 0;
}

static void FindWeaponLessons()
{
    std::call_once(sWeaponLessonsFound, [] {
        for (auto const& kv : *sObjectMgr->GetItemTemplateStore())
            if (kv.second.Class == ITEM_CLASS_WEAPON)
                if (uint32 skill = kv.second.GetSkill(); skill && skill != SKILL_FISHING && skill != SKILL_ASSASSINATION)
                    sWeaponKinds.insert(skill);
        for (auto const& kv : *sObjectMgr->GetCreatureTemplates())
            if (Trainer::Trainer* t = sObjectMgr->GetTrainer(kv.first))
                if (t->GetTrainerType() == Trainer::Type::Tradeskill)
                    for (Trainer::Spell const& sp : t->GetSpells())
                        if (uint32 skill = WeaponKindTaught(sp.SpellId))
                            sWeaponLessons.push_back({ kv.first, sp.SpellId, skill });
        if (sWeaponLessons.empty())
            LOG_ERROR("module", "mod-buddies: no trainer in the world database teaches a weapon kind (looked for profession-type "
                "trainers whose lessons add one of {} weapon skill lines); buddies can only use the weapons they start with. "
                "To debug: does trainer_spell hold spell 227 (Staves)? is SkillLineAbility.dbc loaded?", sWeaponKinds.size());
    });
}

static uint32 WeaponKindsKnown(Player const* p)
{
    uint32 n = 0;
    for (uint32 skill : sWeaponKinds)
        if (p->HasSkill(skill))
            ++n;
    return n;
}

uint32 BuddyWeaponAllowance(uint32 ownerGuid)
{
    FindWeaponLessons();
    uint32 n = 0;
    if (Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid)))
        n = WeaponKindsKnown(owner);
    else if (QueryResult rows = CharacterDatabase.Query("SELECT skill FROM character_skills WHERE guid = {}", ownerGuid))
        do
            if (sWeaponKinds.count((*rows)[0].Get<uint16>()))
                ++n;
        while (rows->NextRow());
    return std::max<uint32>(n, 1);
}

static WeaponLesson const* LessonFor(Player* bot, uint32 skill)
{
    for (WeaponLesson const& l : sWeaponLessons)
        if (l.skill == skill)
            if (Trainer::Trainer* t = sObjectMgr->GetTrainer(l.trainerEntry))
                if (Trainer::Spell const* sp = t->GetSpell(l.spellId); sp && t->IsTrainerValidForPlayer(bot) && t->CanTeachSpell(bot, sp))
                    return &l;
    return nullptr;
}

bool BuddyLearnWeaponKind(Player* bot, uint32 skill, std::string& why)
{
    FindWeaponLessons();
    if (!sWeaponKinds.count(skill) || bot->HasSkill(skill))
        return true;
    if (WeaponLesson const* l = LessonFor(bot, skill))
    {
        LearnOne(bot, l->spellId);
        if (bot->HasSkill(skill))
            return true;
        why = "learning spell " + std::to_string(l->spellId) + " did not give skill " + std::to_string(skill);
        return false;
    }
    why = "no weapon master teaches skill " + std::to_string(skill) + " to its class and race";
    return false;
}

uint32 BuddyFillWeaponKinds(Player* bot, uint32 allowance)
{
    FindWeaponLessons();
    std::vector<uint32> open;
    for (uint32 skill : sWeaponKinds)
        if (!bot->HasSkill(skill) && LessonFor(bot, skill))
            open.push_back(skill);
    Acore::Containers::RandomShuffle(open);
    uint32 learned = 0;
    for (uint32 skill : open)
    {
        if (WeaponKindsKnown(bot) >= allowance)
            break;
        std::string why;
        if (BuddyLearnWeaponKind(bot, skill, why))
            ++learned;
        else
            LOG_ERROR("module", "mod-buddies: buddy {} could not learn weapon kind {}: {}", bot->GetName(), skill, why);
    }
    return learned;
}

static std::once_flag sTrainersFound;
static std::vector<uint32> sClassTrainers;

uint32 BuddyLearnEverything(Player* bot)
{
    uint32 quests = LearnQuestSpells(bot);
    std::call_once(sTrainersFound, [] {
        for (auto const& kv : *sObjectMgr->GetCreatureTemplates())
            if (Trainer::Trainer* t = sObjectMgr->GetTrainer(kv.first))
                if (t->GetTrainerType() == Trainer::Type::Class)
                    sClassTrainers.push_back(kv.first);
    });
    std::vector<Trainer::Trainer*> mine;
    for (uint32 entry : sClassTrainers)
        if (Trainer::Trainer* t = sObjectMgr->GetTrainer(entry))
            if (t->IsTrainerValidForPlayer(bot))
                mine.push_back(t);
    if (mine.empty())
    {
        LOG_ERROR("module", "mod-buddies: no class trainer in the world teaches buddy {} (class {}, race {}); it starts with only "
            "its quest spells", bot->GetName(), bot->getClass(), bot->getRace());
        return quests;
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
    return quests + learned + LearnQuestSpells(bot);
}

struct ProfessionRanks { uint32 skill; uint32 rank[4]; };
static ProfessionRanks const sProfessionRanks[] = {
    { SKILL_ALCHEMY,        {  2259,  3101,  3464, 11611 } },
    { SKILL_BLACKSMITHING,  {  2018,  3100,  3538,  9785 } },
    { SKILL_ENCHANTING,     {  7411,  7412,  7413, 13920 } },
    { SKILL_ENGINEERING,    {  4036,  4037,  4038, 12656 } },
    { SKILL_INSCRIPTION,    { 45357, 45358, 45359, 45360 } },
    { SKILL_JEWELCRAFTING,  { 25229, 25230, 28894, 28895 } },
    { SKILL_LEATHERWORKING, {  2108,  3104,  3811, 10662 } },
    { SKILL_TAILORING,      {  3908,  3909,  3910, 12180 } },
    { SKILL_HERBALISM,      {  2366,  2368,  3570, 11993 } },
    { SKILL_MINING,         {  2575,  2576,  3564, 10248 } },
    { SKILL_SKINNING,       {  8613,  8617,  8618, 10768 } },
    { SKILL_COOKING,        {  2550,  3102,  3413, 18260 } },
    { SKILL_FIRST_AID,      {  3273,  3274,  7924, 10846 } },
    { SKILL_FISHING,        {  7620,  7731,  7732, 18248 } },
};
static constexpr uint8  RANK_FROM_LEVEL[4] = { 1, 10, 20, 35 };
static constexpr uint16 RANK_MAX[4]        = { 75, 150, 225, 300 };
static constexpr uint16 SKILL_PER_LEVEL    = 5;
static constexpr uint16 SKILL_CAP          = 300;
struct RodAtSkill { uint16 skill; uint32 item; };
static constexpr RodAtSkill ENCHANTING_RODS[] = { { 1, 6218 }, { 100, 6339 }, { 150, 11130 }, { 200, 11145 }, { 275, 16207 } };

static std::once_flag sTradeTrainersFound;
static std::vector<uint32> sTradeTrainers;

uint32 BuddyRaiseProfessions(Player* bot, std::string& problems)
{
    uint16 target = std::min<uint16>(uint16(bot->GetLevel()) * SKILL_PER_LEVEL, SKILL_CAP);
    std::set<uint32> rankSpells;
    for (ProfessionRanks const& p : sProfessionRanks)
        for (uint32 r : p.rank)
            rankSpells.insert(r);

    uint32 raised = 0;
    for (ProfessionRanks const& p : sProfessionRanks)
    {
        if (!bot->HasSkill(p.skill))
            continue;
        uint8 rank = 0;
        for (uint8 r = 1; r < 4; ++r)
            if (target > RANK_MAX[r - 1] && bot->GetLevel() >= RANK_FROM_LEVEL[r])
                rank = r;
        for (uint8 r = 0; r <= rank; ++r)
            if (!bot->HasSpell(p.rank[r]))
                bot->learnSpell(p.rank[r], false);
        uint16 max   = std::max<uint16>(RANK_MAX[rank], bot->GetMaxSkillValue(p.skill));
        uint16 value = std::max<uint16>(std::min(target, RANK_MAX[rank]), bot->GetBaseSkillValue(p.skill));
        if (value != bot->GetBaseSkillValue(p.skill) || max != bot->GetMaxSkillValue(p.skill))
        {
            bot->SetSkill(p.skill, std::max<uint16>(rank + 1, bot->GetSkillStep(p.skill)), value, max);
            ++raised;
        }
    }

    std::call_once(sTradeTrainersFound, [] {
        for (auto const& kv : *sObjectMgr->GetCreatureTemplates())
            if (Trainer::Trainer* t = sObjectMgr->GetTrainer(kv.first))
                if (t->GetTrainerType() == Trainer::Type::Tradeskill)
                    sTradeTrainers.push_back(kv.first);
    });
    uint32 recipes = 0;
    for (bool more = true; more; )
    {
        more = false;
        for (uint32 entry : sTradeTrainers)
            if (Trainer::Trainer* t = sObjectMgr->GetTrainer(entry))
                if (t->IsTrainerValidForPlayer(bot))
                    for (Trainer::Spell const& sp : t->GetSpells())
                    {
                        if (!sp.ReqSkillLine || !bot->HasSkill(sp.ReqSkillLine) || !t->CanTeachSpell(bot, &sp))
                            continue;
                        bool isRank = rankSpells.count(sp.SpellId) > 0;
                        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(sp.SpellId))
                            for (SpellEffectInfo const& eff : info->GetEffects())
                                if (eff.IsEffect(SPELL_EFFECT_LEARN_SPELL) && rankSpells.count(eff.TriggerSpell))
                                    isRank = true;
                        if (isRank)
                            continue;
                        uint32 n = LearnOne(bot, sp.SpellId);
                        recipes += n;
                        more = more || n > 0;
                    }
    }

    if (bot->HasSkill(SKILL_ENCHANTING))
    {
        uint32 rod = 0;
        for (RodAtSkill const& r : ENCHANTING_RODS)
            if (bot->GetBaseSkillValue(SKILL_ENCHANTING) >= r.skill)
                rod = r.item;
        if (rod && !bot->HasItemCount(rod, 1, true) && !bot->StoreNewItemInBestSlots(rod, 1))
            problems += "no room in its bags for runed rod " + std::to_string(rod) + "; ";
    }
    return raised + recipes;
}

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
            bot->removeSpell(id, SPEC_MASK_ALL, false);
            ++removed;
        }
    return removed;
}

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

    void OnPlayerLogin(Player* player) override
    {
        if (IsBuddyHunter(player) && !player->GetPet() && !(player->GetPetStable() && player->GetPetStable()->CurrentPet))
            GivePet(player);
    }

    void OnPlayerTalentsReset(Player* player, bool ) override
    {
        if (IsBuddyHunter(player) && player->IsInWorld())
            GivePet(player);
    }
};

void AddSC_buddies_spells()
{
    new buddies_spells_player();
}
