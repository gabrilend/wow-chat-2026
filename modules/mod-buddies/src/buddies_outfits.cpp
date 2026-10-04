/*
 * buddies_outfits.cpp - Sargobras dressed as the owner chose (issue 617f).
 *
 * For a general audience: Sargobras's look (the owner, 2026-10-03, from two
 * screenshots): a human man, skin colour 7, face 8, bald, hair colour 1,
 * bearded; the Cape of the Black Baron, a Black Mageweave Vest over an
 * Orange Mageweave Shirt, Black Tuxedo Pants and Dress Shoes. No picture in
 * the client shows that, and the client isn't patched (2026-09-23), so the
 * server's own "creature outfit" list (patches/B047-creature-outfits.sh)
 * answers the client's "what does this one look like?" for him, the way it
 * answers for a mage's Mirror Image. This file fills that list at startup,
 * gives each Sargobras a human man's body and the mirror-image mark as he
 * enters the world, and lets a game master try other hair, face, skin and
 * beard numbers live (".buddy look"); see Look() for where each number
 * comes from and which are still a guess.
 */

#include "buddies.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "Creature.h"
#include "CreatureOutfits.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <string>
#include <unordered_map>

using namespace Acore::ChatCommands;

// {{{ the look
static uint32 const SARGOBRAS[] = { 6170001, 6170002, 7180001 };   // the valley's, the wanderer, Acherus's
static constexpr uint32 HUMAN_MALE_BODY = 49;      // the human man's own model (creature_model_info 49)
// Item slots in the client's order (CreatureOutfits.h): head, shoulders,
// shirt, chest, waist, legs, feet, wrists, hands, back, tabard.
enum : uint8 { OUTFIT_SHIRT = 2, OUTFIT_CHEST = 3, OUTFIT_LEGS = 5, OUTFIT_FEET = 6, OUTFIT_BACK = 9 };
struct Worn { uint8 slot; uint32 item; char const* name; };
static Worn const WORN[] = {
    { OUTFIT_BACK,  13340, "Cape of the Black Baron" },
    { OUTFIT_CHEST,  9998, "Black Mageweave Vest" },
    { OUTFIT_SHIRT, 10056, "Orange Mageweave Shirt" },
    { OUTFIT_LEGS,   6835, "Black Tuxedo Pants" },
    { OUTFIT_FEET,   6836, "Dress Shoes" },
};

static CreatureOutfit Look()
{
    CreatureOutfit o;
    o.displayId  = HUMAN_MALE_BODY;
    o.race       = 1;                              // human
    o.gender     = 0;                              // male
    // The owner's screenshot came from a customizer that counts from 1
    // (skin 7, face 8, hair colour 1); the client counts from 0. The first
    // try (2026-10-03) used them as given and drew the wrong face, so they
    // are taken one lower. Hair and beard are from the client's own tables
    // (data-files/dbc): CharHairGeosets.dbc, human male, style 0 is the
    // only one that shows the scalp (bald); CharacterFacialHairStyles.dbc,
    // human male, style 4 is the only one with all three beard parts
    // (moustache, chin, sideburns), as in the owner's picture.
    o.skin       = 6;                              // the screenshot's 7
    o.face       = 7;                              // the screenshot's 8
    o.hair       = 0;                              // bald
    o.hairColor  = 0;                              // the screenshot's 1
    o.facialHair = 4;                              // moustache, chin and sideburns
    for (Worn const& w : WORN)
    {
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(w.item);
        if (!proto)
        {
            LOG_ERROR("module", "mod-buddies: Sargobras's {} (item {}) is not in the world database; he goes without it",
                w.name, w.item);
            continue;
        }
        o.items[w.slot] = proto->DisplayInfoID;
    }
    return o;
}

static void ListAll(CreatureOutfit const& o)
{
    for (uint32 entry : SARGOBRAS)
        CreatureOutfits::Set(entry, o);
}
// }}}

// {{{ the startup and the creatures
class buddies_outfits_world : public WorldScript
{
public:
    buddies_outfits_world() : WorldScript("buddies_outfits_world", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        if (!BuddiesEnabled())
            return;
        ListAll(Look());
        LOG_INFO("module", ">> mod-buddies: Sargobras is dressed (617f): a human man in the Black Baron's cape (B047's outfit list)");
    }
};

class buddies_outfits_creature : public AllCreatureScript
{
public:
    buddies_outfits_creature() : AllCreatureScript("buddies_outfits_creature") { }

    // A listed creature gets the outfit's body and the mirror-image mark,
    // which makes the client ask for (and draw) the listed look.
    void OnCreatureAddWorld(Creature* creature) override
    {
        CreatureOutfit o;
        if (!CreatureOutfits::Find(creature->GetEntry(), o))
            return;
        creature->SetDisplayId(o.displayId);
        creature->SetNativeDisplayId(o.displayId);
        creature->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
    }
};
// }}}

// {{{ the command
// ".buddy look <skin|face|hair|haircolor|beard> <number>": changes that
// part of Sargobras's look for this server run (the numbers to keep go into
// Look() above). The client asks for a creature's look when it first sees
// it, so walk out of sight and back (or log out and in) to see a change.
class buddies_outfits_command : public CommandScript
{
public:
    buddies_outfits_command() : CommandScript("buddies_outfits_command") { }

    ChatCommandTable GetCommands() const override
    {
        // multi-word names join the ".buddy" table the beds file starts
        static ChatCommandTable commandTable =
        {
            { "buddy look", HandleLook, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    static bool HandleLook(ChatHandler* handler, std::string part, uint32 value)
    {
        static std::unordered_map<std::string, uint8 CreatureOutfit::*> const parts = {
            { "skin", &CreatureOutfit::skin }, { "face", &CreatureOutfit::face }, { "hair", &CreatureOutfit::hair },
            { "haircolor", &CreatureOutfit::hairColor }, { "beard", &CreatureOutfit::facialHair },
        };
        std::transform(part.begin(), part.end(), part.begin(), [](unsigned char c) { return char(std::tolower(c)); });
        auto it = parts.find(part);
        if (it == parts.end() || value > 255)
        {
            handler->PSendSysMessage("Usage: .buddy look <skin|face|hair|haircolor|beard> <0-255>");
            return false;
        }
        CreatureOutfit o;
        if (!CreatureOutfits::Find(SARGOBRAS[0], o))
        {
            handler->PSendSysMessage("Sargobras has no outfit listed (is the buddy module on, and B047 built in?).");
            return false;
        }
        o.*(it->second) = uint8(value);
        ListAll(o);
        handler->PSendSysMessage("Sargobras's {} is now {}. Walk out of sight and back to see it; to keep it, it goes into "
            "buddies_outfits.cpp.", part, value);
        return true;
    }
};
// }}}

void AddSC_buddies_outfits()
{
    new buddies_outfits_world();
    new buddies_outfits_creature();
    new buddies_outfits_command();
}
