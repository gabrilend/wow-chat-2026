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
    // quest spells first, free: the trainer's later ranks of a quest's
    // totem or Bear Form ask for them (see BuddyLearnEverything)
    uint32 quest = LearnQuestSpells(bot);
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
    BuddyTrace(bot, "town: trained at {}: {} lessons bought, {} quest spells added", npc->GetName(), learned, quest);
    return learned + quest;
}
// }}}

// {{{ weapon skills, as many as the owner's
// The owner's rule (2026-10-15): "buddy-bots should have one weaponskill
// trained (minimum 1, the weapon they have equipped at the start of the
// game) per weaponskill that the player trains. So the buddy-bots of a
// mage who has few weapon skills will have fewer themselves."
//
// And, the same day, refined: "the buddy-bot at each tier spawns in with
// possibly a different weapon type equipped. That one they should know.
// Otherwise, they should learn a random weapon skill from what their
// class can know, one for each of the player's learned weapon skills.
// Then, at capital cities and such, they can learn more."
//
// So: the kind of every weapon its kit hands it is learned, whatever the
// count (BuddyLearnWeaponKind); then, when it is made, random kinds its
// class and race can learn are added until it knows as many kinds as its
// owner, at least one (BuddyFillWeaponKinds). What it starts with counts,
// and it is never made to forget one. Learning more at weapon masters in
// the capitals is planned (617n).
//
// Weapon masters teach these, and they are filed as profession trainers
// in the world database (trainer type 2), so the class-trainer sweep below
// never met them: the hunter Montahmu, made at 44 on 2026-10-15, had its
// kit staff and gun refused, its starting weapons already gone, and fought
// Uldaman with its fishing pole. Every weapon master lesson is gathered
// once, with the kind it teaches; the race-and-class check inside
// CanTeachSpell keeps a rogue from staves.
struct WeaponLesson { uint32 trainerEntry; uint32 spellId; uint32 skill; };
static std::once_flag sWeaponLessonsFound;
static std::vector<WeaponLesson> sWeaponLessons;
static std::set<uint32> sWeaponKinds;   // skill lines weapon items ask for; not Fishing, not the unused spear line (253)

// The weapon kind a lesson (or what it teaches) adds, 0 for none.
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
        n = WeaponKindsKnown(owner);                   // online: what it knows this moment
    else if (QueryResult rows = CharacterDatabase.Query("SELECT skill FROM character_skills WHERE guid = {}", ownerGuid))
        do
            if (sWeaponKinds.count((*rows)[0].Get<uint16>()))
                ++n;
        while (rows->NextRow());                       // offline: as last saved
    return std::max<uint32>(n, 1);                     // the owner's minimum: one, the weapon it starts with
}

// The lesson that teaches `skill` to this buddy, if any weapon master has one.
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
        return true;                                   // not a weapon kind (nothing to learn), or known already
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
    // the kinds it could still learn, each once, in a random order
    std::vector<uint32> open;
    for (uint32 skill : sWeaponKinds)
        if (!bot->HasSkill(skill) && LessonFor(bot, skill))
            open.push_back(skill);
    Acore::Containers::RandomShuffle(open);
    uint32 learned = 0;
    for (uint32 skill : open)
    {
        if (WeaponKindsKnown(bot) >= allowance)
            break;                                     // as many as its owner: enough
        std::string why;
        if (BuddyLearnWeaponKind(bot, skill, why))
            ++learned;
        else
            LOG_ERROR("module", "mod-buddies: buddy {} could not learn weapon kind {}: {}", bot->GetName(), skill, why);
    }
    return learned;
}
// }}}

// {{{ BuddyLearnEverything
// Every class trainer of the world, by creature entry, found once.
static std::once_flag sTrainersFound;
static std::vector<uint32> sClassTrainers;

uint32 BuddyLearnEverything(Player* bot)
{
    // quest spells first: the first totem of each element and Bear Form
    // come from class quests, and the trainers' later ranks (Searing
    // Totem 2, Maul, Swipe, Dire Bear Form ...) ask for them. Learned after
    // the trainers, as until 2026-10-15, those later ranks were never
    // offered (a level-44 druid made knowing Bear Form and no bear
    // ability). The owner: "They were just in the capital, they are fully
    // trained." Weapon kinds are not taught here: the kit teaches them,
    // as many as the owner knows (BuddyLearnWeaponKind).
    uint32 quests = LearnQuestSpells(bot);
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
    return quests + learned + LearnQuestSpells(bot);   // again: a quest spell that asks for a rank just learned
}
// }}}

// {{{ BuddyRaiseProfessions
// A buddy made at a level practises its professions as if it had been
// playing (owner, 2026-10-15: "when created at a certain level, they
// should have a proficiency level (and abilities learned, and required
// items given like runed arcanite rods) appropriate for their character
// level"): every profession it has, cooking, first aid and fishing too,
// at five points a level up to 300 (185's rate; basic stops at 300), the
// rank that skill needs (Apprentice 75, Journeyman 150 from level 10,
// Expert 225 from 20, Artisan 300 from 35, as the trainers teach them),
// every recipe its profession's trainers teach at or below that skill and
// level, and an enchanter's runed rod of its skill. Never lowers a skill.
//
// The rank spells are learned and the skill set directly, the death knight
// way (MaxDeathKnightProfessions): a rank is learned by casting it, and a
// buddy being made isn't in the world to cast. Rank numbers read from
// Spell.dbc, 2026-10-15 (all 56 by name).
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
static constexpr uint16 SKILL_CAP          = 300;   // basic's professions stop here (155n)
// an enchanter's rod by the skill its recipe needs: copper, silver,
// golden, truesilver, arcanite (item_template, 2026-10-15)
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

    // the skill and its rank
    uint32 raised = 0;
    for (ProfessionRanks const& p : sProfessionRanks)
    {
        if (!bot->HasSkill(p.skill))
            continue;
        uint8 rank = 0;                                // the highest rank its skill and level call for
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

    // the recipes: every lesson of a profession trainer for a skill it has
    // (never a new profession's first rank, which has no skill asked for;
    // never a rank lesson, done above), pass after pass
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
                            continue;                  // a rank: set above, by its skill
                        uint32 n = LearnOne(bot, sp.SpellId);
                        recipes += n;
                        more = more || n > 0;
                    }
    }

    // an enchanter's rod of its skill
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
