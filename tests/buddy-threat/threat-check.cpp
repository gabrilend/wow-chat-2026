// threat-check.cpp - checks buddies_threat.h (issue 625j): whom an enemy
// attacks, the way the server decides it, and what each lever does to its
// threat list; and that the levers read from the game's spell table are
// the ones the threat economy names.

#include "buddies_threat.h"

#include <cstdio>

using namespace BuddyThreat;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

int main()
{
    // who the enemy attacks: the tank (0) has it, with 1000 threat
    std::vector<Entry> list = { { 1000, 2, 0, true }, { 1050, 2, 0, true } };
    check(Attention(list, 0) == 0, "a warrior 5% over the tank, in melee: the tank keeps it");
    list[1].threat = 1150;
    check(Attention(list, 0) == 1, "10% over, in melee: the warrior takes it");
    list = { { 1000, 2, 0, true }, { 1200, 2, 0, false } };
    check(Attention(list, 0) == 0, "a mage 20% over at range: the tank keeps it");
    list[1].threat = 1350;
    check(Attention(list, 0) == 1, "30% over at range: the mage takes it");
    list = { { 1000, 2, 0, true }, { 1250, 2, 0, false }, { 1150, 2, 0, true } };
    check(Attention(list, 0) == 2, "a mage 25% over at range and a rogue 15% over in melee: the rogue takes it");
    check(Attention(list, -1) == 1, "no one attacked yet: the highest, the mage");

    // Divine Shield on the tank: passed over, not wiped (the owner asked
    // "Because that's what happens, right?"; the server keeps the threat)
    list = { { 1000, 2, 0, true }, { 800, 2, 0, true } };
    Immune(list, 0);
    check(Attention(list, 0) == 1 && list[0].threat == 1000, "the shielded tank is passed over, its 1000 threat kept: the fury warrior tanks");
    Comeback(list, 0);
    check(Attention(list, 1) == 0, "the shield ends and the tank acts: its kept threat takes the attention back");
    list = { { 1000, 1, 0, true }, { 800, 1, 0, true } };
    check(Attention(list, -1) == 0, "everyone passed over: the enemy still attacks the highest");

    // taunt, share, hand, leave
    list = { { 500, 2, 0, true }, { 900, 2, 0, true } };
    Taunt(list, 0);
    check(Attention(list, 1) == 0 && list[0].threat == 900, "a taunt raises the tank to the top and takes the attention");
    list = { { 1000, 2, 0, true }, { 2000, 2, 0, false } };
    Share(list, 1, -50);
    check(list[1].threat == 1000, "Soulshatter halves the warlock's threat");
    Hand(list, 0, 600);
    check(list[0].threat == 1600 && Attention(list, 1) == 0, "Misdirection hands 600 to the tank, who takes the attention");
    Leave(list, 1);
    check(list[1].state == 0 && list[1].threat == 0, "Vanish: out of the fight, its threat dropped");
    Leave(list, 0);
    check(Attention(list, 0) == -1, "everyone out of the fight: no one attacked");

    // the levers, as the game's spell table says (scripts/generate-ability-data)
    check(Does(LeverOf(1, "taunt"), "taunt") && Does(LeverOf(11, "growl"), "taunt"), "Taunt and the druid's Growl taunt");
    check(Does(LeverOf(2, "righteous defense"), "taunt") && Does(LeverOf(6, "death grip"), "taunt"),
          "Righteous Defense and Death Grip taunt, through the spells their scripts cast");
    check(Does(LeverOf(3, "misdirection"), "hand") && Does(LeverOf(4, "tricks of the trade"), "hand"), "Misdirection and Tricks of the Trade hand threat on");
    check(Does(LeverOf(4, "vanish"), "leave") && Does(LeverOf(3, "feign death"), "leave") && Does(LeverOf(8, "invisibility"), "leave"),
          "Vanish, Feign Death and Invisibility leave the fight");
    BuddyThreatLeverRow const* shatter = LeverOf(9, "soulshatter");
    check(Does(shatter, "share") && shatter->amount == -50, "Soulshatter cuts threat by half");
    check(Does(LeverOf(4, "feint"), "threat") && LeverOf(4, "feint")->amount < 0, "Feint takes threat away");
    check(Does(LeverOf(2, "divine shield"), "immune") && Does(LeverOf(2, "hand of protection"), "immune") && Does(LeverOf(8, "ice block"), "immune"),
          "Divine Shield, Hand of Protection and Ice Block make their receiver immune");
    check(LeverOf(2, "divine protection") == nullptr, "Divine Protection moves no attention (a halving of damage, not an immunity)");
    check(Does(LeverOf(3, "growl"), "threat"), "the hunter pet's Growl is among the levers (pets' abilities are read too, 625m)");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
