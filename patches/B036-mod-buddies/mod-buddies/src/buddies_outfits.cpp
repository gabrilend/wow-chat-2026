
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

static uint32 const SARGOBRAS[] = { 6170001, 6170002, 7180001, 7180002 };
static constexpr uint32 HUMAN_MALE_BODY = 49;
enum : uint8 { OUTFIT_HEAD = 0, OUTFIT_SHIRT = 2, OUTFIT_CHEST = 3, OUTFIT_LEGS = 5, OUTFIT_FEET = 6, OUTFIT_BACK = 9 };
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
    o.race       = 1;
    o.gender     = 0;
    o.skin       = 6;
    o.face       = 7;
    o.hair       = 0;
    o.hairColor  = 0;
    o.facialHair = 4;
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

static constexpr uint32 SARGOBRAS_HATTED = 6170003;
static constexpr uint32 RIGOBERTOS_HAT   = 21615;

static void ListAll(CreatureOutfit const& o)
{
    for (uint32 entry : SARGOBRAS)
        CreatureOutfits::Set(entry, o);
    CreatureOutfit hatted = o;
    if (ItemTemplate const* hat = sObjectMgr->GetItemTemplate(RIGOBERTOS_HAT))
        hatted.items[OUTFIT_HEAD] = hat->DisplayInfoID;
    else
        LOG_ERROR("module", "mod-buddies: Don Rigoberto's Lost Hat (item {}) is not in the world database; the hatted "
            "Sargobras goes bare-headed", RIGOBERTOS_HAT);
    CreatureOutfits::Set(SARGOBRAS_HATTED, hatted);
}

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

class buddies_outfits_command : public CommandScript
{
public:
    buddies_outfits_command() : CommandScript("buddies_outfits_command") { }

    ChatCommandTable GetCommands() const override
    {
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

void AddSC_buddies_outfits()
{
    new buddies_outfits_world();
    new buddies_outfits_creature();
    new buddies_outfits_command();
}
