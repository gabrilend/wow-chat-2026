#!/usr/bin/env bash
# B034 - A jewelcrafter cuts the other player's gem through the trade window
# Issue 155p (basic, 2026-09-25).
#
# For a general audience: epic Wrath gems, cut or uncut, bind on pickup, and
# a bound gem can't be handed to a jewelcrafter to cut. Ritz, 2026-09-25: "I
# want the cut ones to also bind on pickup. If the jewelcrafter can cut the
# gem when it's in the 'will not be traded' slot, then it's worth it,
# because they can exchange gold if they'd like at the same transaction." /
# "ideally if we could do that, I'd prefer it."
#
# How it plays: the gem's owner opens a trade with a jewelcrafter and puts
# the uncut gem in the "will not be traded" slot; the jewelcrafter types
# ".cut" and shift-clicks the recipe (the ".cut" command is in basic's
# compiled rules, src/cpp-basic/basic_rules.cpp); the trade window shows the
# cut under the gem, the way it shows a pending enchantment; gold can go
# either way in the same trade; when both accept, the owner's uncut gem is
# used up and the cut gem goes into the owner's bags, bound to them, with
# the jewelcrafter as its crafter, and the jewelcrafter gets the skill-up.
# (The stock Create button can't do this: the client disables it unless the
# crafter's own bags hold the reagents, read in the client's
# Blizzard_TradeSkillUI.lua.)
#
# Where (all in src/server/game/Handlers/TradeHandler.cpp):
#   1. helpers before WorldSession::SendTradeStatus: is this spell a gem cut
#      (it creates one gem from one reagent), can this cut happen, do it;
#   2. HandleAcceptTradeOpcode, each side's pending-spell check: a gem cut
#      is checked (gem still there, recipe known, room in the owner's bags;
#      else the accept is refused before anything changes hands) and kept
#      out of the stock spell path, which would look for the reagent in the
#      crafter's own bags;
#   3. after items and gold have moved, before stock spells are cast: the
#      cut itself.
#
# Mechanics: insertions and two replaced lines inside ">>> B034 ... BEGIN" /
# "<<< B034 ... END" marker comments, replaced lines kept as
# "//B034-ORIG:<line>"; the revert removes the blocks and restores those
# lines. Each anchor must occur exactly once or the patch stops.
# Parallelizable: Yes (unique file)

B034_TAG='B034-trade-gem-cut'
B034_HELPERS_ANCHOR='void WorldSession::SendTradeStatus(TradeStatusInfo const& info)'
B034_MY_ANCHOR='        if (uint32 my_spell_id = my_trade->GetSpell())'
B034_HIS_ANCHOR='        if (uint32 his_spell_id = his_trade->GetSpell())'
B034_CUT_ANCHOR='        if (my_spell)'

# {{{ patch_B034_trade_gem_cut
patch_B034_trade_gem_cut() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/TradeHandler.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B034] ERROR: ${FILE} missing"; return 1; }
    grep -qF "${B034_TAG}" "${FILE}" && return 0                  # witness guard
    local a count
    for a in "${B034_HELPERS_ANCHOR}" "${B034_MY_ANCHOR}" "${B034_HIS_ANCHOR}" "${B034_CUT_ANCHOR}"; do
        count=$(grep -cxF -- "${a}" "${FILE}")
        if [[ "${count}" -ne 1 ]]; then
            echo "  [B034] ERROR: expected exactly one line '${a}' in ${FILE}, found ${count}"
            return 1
        fi
    done
    H="${B034_HELPERS_ANCHOR}" MY="${B034_MY_ANCHOR}" HIS="${B034_HIS_ANCHOR}" CUT="${B034_CUT_ANCHOR}" awk '
        $0 == ENVIRON["H"] {
            print "// >>> B034-trade-gem-cut BEGIN (helpers)"
            print "// Everland Ghostsong (issue 155p): a jewelcrafter cuts the other player'"'"'s gem"
            print "// in the \"will not be traded\" slot. A gem cut: a spell that creates one gem"
            print "// from a single reagent (the uncut gem)."
            print "#include \"ObjectMgr.h\""
            print "static bool B034_IsGemCut(uint32 spellId, uint32* reagent = nullptr, uint32* count = nullptr, uint32* product = nullptr)"
            print "{"
            print "    SpellInfo const* info = spellId ? sSpellMgr->GetSpellInfo(spellId) : nullptr;"
            print "    if (!info || info->Reagent[0] <= 0 || info->Reagent[1] > 0)"
            print "        return false;"
            print "    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)"
            print "    {"
            print "        if (info->Effects[i].Effect != SPELL_EFFECT_CREATE_ITEM)"
            print "            continue;"
            print "        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(info->Effects[i].ItemType);"
            print "        if (!proto || proto->Class != ITEM_CLASS_GEM)"
            print "            return false;"
            print "        if (reagent) *reagent = uint32(info->Reagent[0]);"
            print "        if (count)   *count   = info->ReagentCount[0];"
            print "        if (product) *product = info->Effects[i].ItemType;"
            print "        return true;"
            print "    }"
            print "    return false;"
            print "}"
            print ""
            print "// Can the cutter cut this gem for its owner now? Tells both why not."
            print "static bool B034_CanCut(Player* cutter, Player* owner, uint32 spellId, Item* gem)"
            print "{"
            print "    uint32 reagent = 0, count = 0, product = 0;"
            print "    char const* why = nullptr;"
            print "    ItemPosCountVec dest;"
            print "    if (!B034_IsGemCut(spellId, &reagent, &count, &product))"
            print "        why = \"That recipe is not a gem cut.\";"
            print "    else if (!cutter->HasSpell(spellId))"
            print "        why = \"The jewelcrafter does not know that cut.\";"
            print "    else if (!gem || gem->GetEntry() != reagent || gem->GetCount() < count)"
            print "        why = \"The uncut gem for that cut is not in the \\\"will not be traded\\\" slot.\";"
            print "    else if (owner->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, product, 1) != EQUIP_ERR_OK)"
            print "        why = \"There is no room in the gem owner'"'"'s bags for the cut gem.\";"
            print "    if (!why)"
            print "        return true;"
            print "    ChatHandler(cutter->GetSession()).SendSysMessage(why);"
            print "    ChatHandler(owner->GetSession()).SendSysMessage(why);"
            print "    return false;"
            print "}"
            print ""
            print "// The cut: the owner'"'"'s uncut gem is used up, the cut gem is stored in the"
            print "// owner'"'"'s bags (binding as its template says), crafted by the cutter."
            print "static void B034_Cut(Player* cutter, Player* owner, uint32 spellId, Item* gem)"
            print "{"
            print "    uint32 reagent = 0, count = 0, product = 0;"
            print "    if (!B034_IsGemCut(spellId, &reagent, &count, &product) || !B034_CanCut(cutter, owner, spellId, gem))"
            print "        return;"
            print "    ItemPosCountVec dest;"
            print "    if (owner->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, product, 1) != EQUIP_ERR_OK)"
            print "        return;"
            print "    uint32 used = count;"
            print "    owner->DestroyItemCount(gem, used, true);"
            print "    if (Item* cut = owner->StoreNewItem(dest, product, true))"
            print "    {"
            print "        cut->SetGuidValue(ITEM_FIELD_CREATOR, cutter->GetGUID());"
            print "        owner->SendNewItem(cut, 1, true, false);"
            print "    }"
            print "    cutter->UpdateCraftSkill(spellId);"
            print "}"
            print "// <<< B034-trade-gem-cut END (helpers)"
            print; next
        }
        $0 == ENVIRON["MY"] {
            print "        // >>> B034-trade-gem-cut BEGIN (my side)"
            print "//B034-ORIG:" $0
            print "        if (B034_IsGemCut(my_trade->GetSpell()) && !B034_CanCut(_player, trader, my_trade->GetSpell(), his_trade->GetItem(TRADE_SLOT_NONTRADED)))"
            print "        {"
            print "            clearAcceptTradeMode(my_trade, his_trade);"
            print "            clearAcceptTradeMode(myItems, hisItems);"
            print "            my_trade->SetSpell(0);"
            print "            return;"
            print "        }"
            print "        if (uint32 my_spell_id = B034_IsGemCut(my_trade->GetSpell()) ? 0 : my_trade->GetSpell())"
            print "        // <<< B034-trade-gem-cut END (my side)"
            next
        }
        $0 == ENVIRON["HIS"] {
            print "        // >>> B034-trade-gem-cut BEGIN (his side)"
            print "//B034-ORIG:" $0
            print "        if (B034_IsGemCut(his_trade->GetSpell()) && !B034_CanCut(trader, _player, his_trade->GetSpell(), my_trade->GetItem(TRADE_SLOT_NONTRADED)))"
            print "        {"
            print "            clearAcceptTradeMode(my_trade, his_trade);"
            print "            clearAcceptTradeMode(myItems, hisItems);"
            print "            his_trade->SetSpell(0);"
            print "            delete my_spell;"
            print "            return;"
            print "        }"
            print "        if (uint32 his_spell_id = B034_IsGemCut(his_trade->GetSpell()) ? 0 : his_trade->GetSpell())"
            print "        // <<< B034-trade-gem-cut END (his side)"
            next
        }
        $0 == ENVIRON["CUT"] {
            print "        // >>> B034-trade-gem-cut BEGIN (cut)"
            print "        if (B034_IsGemCut(my_trade->GetSpell()))"
            print "            B034_Cut(_player, trader, my_trade->GetSpell(), his_trade->GetItem(TRADE_SLOT_NONTRADED));"
            print "        if (B034_IsGemCut(his_trade->GetSpell()))"
            print "            B034_Cut(trader, _player, his_trade->GetSpell(), my_trade->GetItem(TRADE_SLOT_NONTRADED));"
            print "        // <<< B034-trade-gem-cut END (cut)"
            print; next
        }
        { print }' "${FILE}" > "${FILE}.b034" && mv "${FILE}.b034" "${FILE}"
    echo "  [B034] A jewelcrafter can cut the other player's gem in the trade window"
}
# }}}

# {{{ unpatch_B034_trade_gem_cut
unpatch_B034_trade_gem_cut() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/TradeHandler.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B034-trade-gem-cut" "${FILE}" || return 0            # nothing of ours
    awk '
        /\/\/ >>> B034-trade-gem-cut BEGIN/ { inblock = 1; next }
        inblock && /^\/\/B034-ORIG:/        { print substr($0, 13); next }   # 12 = length("//B034-ORIG:")
        inblock && /\/\/ <<< B034-trade-gem-cut END/ { inblock = 0; next }
        inblock                              { next }
        { print }' "${FILE}" > "${FILE}.b034" && mv "${FILE}.b034" "${FILE}"
    return 0
}
# }}}
