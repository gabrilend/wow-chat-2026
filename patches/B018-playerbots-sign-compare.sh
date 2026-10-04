#!/usr/bin/env bash
# B018-playerbots-sign-compare.sh
# Fixes sign comparison warnings in mod-playerbots
#
# Warning: comparison of integers of different signs [-Wsign-compare]
#
# Patterns fixed:
#   1. int loop counters vs .size() -> size_t counters
#   2. int vs uint32 with -1 sentinel -> cast to uint32
#   3. string::find() == -1 -> string::npos
#   4. GetMapId() == -1 -> static_cast<uint32>(-1)
#
# Affected files (13 warnings):
#   PlayerbotAIConfig.cpp:918,925,927,974,976
#   BattleGroundTactics.cpp:1371,3329
#   ChatShortcutActions.cpp:75
#   ChooseTravelTargetAction.cpp:931
#   FollowActions.cpp:221
#   GenericSpellActions.cpp:180
#   InventoryAction.cpp:375,389
#   MovementActions.cpp:1870,2301
#   QuestAction.cpp:416
#   TradeAction.cpp:72
#   TravelAction.cpp:40

# {{{ patch_B018_playerbots_sign_compare
#
# Rewritten 2026-10-03 as exact whole-line edits (patches.sh,
# line_edits_apply / line_edits_revert): each edited line carries the tag
# "  // B018", the revert turns back only tagged lines, and an old line not
# found the expected number of times stops the patch as stale. The old sed
# revert also changed lines upstream had since written the fixed way
# (scripts/verify-patches). All five comparisons still need their casts upstream.

# path (from the source root) <TAB> old line <TAB> new line
B018_EDITS=$(cat <<'EDITS'
modules/mod-playerbots/src/Ai/Base/Value/SpellIdValue.cpp	        if (!useByItem && (tolower(spellName[0]) != firstSymbol || strlen(spellName) != spellLength ||	        if (!useByItem && (tolower(spellName[0]) != firstSymbol || strlen(spellName) != static_cast<size_t>(spellLength) ||
modules/mod-playerbots/src/Ai/Base/Value/SpellIdValue.cpp	            if (tolower(spellName[0]) != firstSymbol || strlen(spellName) != spellLength ||	            if (tolower(spellName[0]) != firstSymbol || strlen(spellName) != static_cast<size_t>(spellLength) ||
modules/mod-playerbots/src/Ai/Base/Value/SpellIdValue.cpp	        if (tolower(spellName[0]) != firstSymbol || strlen(spellName) != spellLength ||	        if (tolower(spellName[0]) != firstSymbol || strlen(spellName) != static_cast<size_t>(spellLength) ||
modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp	        if (proto->Quality != desiredQuality)	        if (proto->Quality != static_cast<uint32>(desiredQuality))
modules/mod-playerbots/src/PlayerbotAIConfig.cpp	    for (int tab = 0; tab < 3; tab++)	    for (size_t tab = 0; tab < 3; tab++)
EDITS
)

# {{{ patch_B018_playerbots_sign_compare
patch_B018_playerbots_sign_compare() {
    line_edits_apply B018 <<< "${B018_EDITS}"
}
# }}}

# {{{ unpatch_B018_playerbots_sign_compare
unpatch_B018_playerbots_sign_compare() {
    line_edits_revert B018 <<< "${B018_EDITS}"
}
# }}}
