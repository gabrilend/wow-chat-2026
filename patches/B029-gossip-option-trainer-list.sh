#!/usr/bin/env bash

B029_BEGIN='// >>> B029-gossip-option-trainer BEGIN'
B029_END='// <<< B029-gossip-option-trainer END'

_b029_replace_line() {
    local file="$1" orig="$2" block="$3"
    local count
    count=$(grep -cxF -- "${orig}" "${file}")
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B029] ERROR: expected exactly one line '${orig}' in ${file}, found ${count}"
        return 1
    fi
    ORIG="${orig}" BEGIN_M="${B029_BEGIN}" END_M="${B029_END}" awk -v blockfile="${block}" '
        $0 == ENVIRON["ORIG"] && !done {
            match($0, /^[ \t]*/); ind = substr($0, 1, RLENGTH)
            print ind ENVIRON["BEGIN_M"]
            print "//B029-ORIG:" $0
            while ((getline l < blockfile) > 0) print l
            print ind ENVIRON["END_M"]
            done = 1; next
        }
        { print }' "${file}" > "${file}.b029" && mv "${file}.b029" "${file}"
}

_b029_insert_after() {
    local file="$1" anchor="$2" block="$3"
    local count
    count=$(grep -cxF -- "${anchor}" "${file}")
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B029] ERROR: expected exactly one anchor '${anchor}' in ${file}, found ${count}"
        return 1
    fi
    ANCHOR="${anchor}" BEGIN_M="${B029_BEGIN}" END_M="${B029_END}" awk -v blockfile="${block}" '
        { print }
        $0 == ENVIRON["ANCHOR"] && !done {
            print ENVIRON["BEGIN_M"]
            while ((getline l < blockfile) > 0) print l
            print ENVIRON["END_M"]
            done = 1
        }' "${file}" > "${file}.b029" && mv "${file}.b029" "${file}"
}

patch_B029_gossip_option_trainer_list() {
    local OBJMGR_H="${AC_CODE_DIR}/src/server/game/Globals/ObjectMgr.h"
    local OBJMGR_CPP="${AC_CODE_DIR}/src/server/game/Globals/ObjectMgr.cpp"
    local SESSION_H="${AC_CODE_DIR}/src/server/game/Server/WorldSession.h"
    local NPC_CPP="${AC_CODE_DIR}/src/server/game/Handlers/NPCHandler.cpp"
    local GOSSIP_CPP="${AC_CODE_DIR}/src/server/game/Entities/Player/PlayerGossip.cpp"
    local f
    for f in "${OBJMGR_H}" "${OBJMGR_CPP}" "${SESSION_H}" "${NPC_CPP}" "${GOSSIP_CPP}"; do
        [[ -f "${f}" ]] || { echo "  [B029] ERROR: ${f} not found"; return 1; }
    done

    grep -q "B029-gossip-option-trainer" "${NPC_CPP}" && return 0
    echo "  [B029] Trainer gossip options can name their trainer list (155e)"

    local T
    T="$(mktemp -d)"

    cat > "${T}/1" << 'CPP'
    Trainer::Trainer* GetTrainerById(uint32 trainerId);  // by trainer.Id, not creature entry
CPP
    _b029_insert_after "${OBJMGR_H}" '    Trainer::Trainer* GetTrainer(uint32 creatureId);' "${T}/1" || return 1

    cat > "${T}/2" << 'CPP'
Trainer::Trainer* ObjectMgr::GetTrainerById(uint32 trainerId)
{
    return Acore::Containers::MapGetValuePtr(_trainers, trainerId);
}

CPP
    local anchor_cpp='int ObjectMgr::LoadReferenceVendor(int32 vendor, int32 item, std::set<uint32>* skip_vendors)'
    local line
    line=$(grep -nxF -- "${anchor_cpp}" "${OBJMGR_CPP}" | cut -d: -f1)
    [[ -n "${line}" ]] || { echo "  [B029] ERROR: LoadReferenceVendor anchor not found in ${OBJMGR_CPP}"; return 1; }
    { head -n $((line - 1)) "${OBJMGR_CPP}"; echo "${B029_BEGIN}"; cat "${T}/2"; echo "${B029_END}"; tail -n +"${line}" "${OBJMGR_CPP}"; } > "${OBJMGR_CPP}.b029" \
        && mv "${OBJMGR_CPP}.b029" "${OBJMGR_CPP}"

    cat > "${T}/3" << 'CPP'
    void SendTrainerList(Creature* npc, uint32 trainerIdOverride = 0);
CPP
    _b029_replace_line "${SESSION_H}" '    void SendTrainerList(Creature* npc);' "${T}/3" || return 1
    cat > "${T}/4" << 'CPP'
    // Trainer list opened through a gossip option that named its own list
    // (B029). The buy-spell packet carries only the NPC, so remember which
    // list this player is looking at, and at which NPC.
    ObjectGuid _optionTrainerNpc;
    uint32 _optionTrainerId = 0;
CPP
    _b029_insert_after "${SESSION_H}" '    Player* _player;' "${T}/4" || return 1

    cat > "${T}/5" << 'CPP'
void WorldSession::SendTrainerList(Creature* npc, uint32 trainerIdOverride)
CPP
    _b029_replace_line "${NPC_CPP}" 'void WorldSession::SendTrainerList(Creature* npc)' "${T}/5" || return 1
    cat > "${T}/6" << 'CPP'
    // An override comes only from a gossip option on an NPC without its own
    // list (see PlayerGossip). Remember it for the buy handler; opening any
    // list without an override forgets it.
    Trainer::Trainer const* trainer = trainerIdOverride ? sObjectMgr->GetTrainerById(trainerIdOverride)
                                                        : sObjectMgr->GetTrainer(npc->GetEntry());
    _optionTrainerNpc = trainerIdOverride ? npc->GetGUID() : ObjectGuid::Empty;
    _optionTrainerId  = trainerIdOverride;
CPP
    _b029_replace_line "${NPC_CPP}" '    Trainer::Trainer const* trainer = sObjectMgr->GetTrainer(npc->GetEntry());' "${T}/6" || return 1
    cat > "${T}/7" << 'CPP'
    Trainer::Trainer* trainer = (_optionTrainerId && _optionTrainerNpc == npc->GetGUID())
                                ? sObjectMgr->GetTrainerById(_optionTrainerId)
                                : sObjectMgr->GetTrainer(npc->GetEntry());
CPP
    _b029_replace_line "${NPC_CPP}" '    Trainer::Trainer* trainer = sObjectMgr->GetTrainer(npc->GetEntry());' "${T}/7" || return 1

    cat > "${T}/8" << 'CPP'
                    // B029: an NPC without its own list may name one per option
                    // (ActionMenuID), as vendor options already may.
                    Trainer::Trainer const* trainer = sObjectMgr->GetTrainer(creature->GetEntry());
                    if (!trainer && itr->second.ActionMenuID)
                    {
                        trainer = sObjectMgr->GetTrainerById(itr->second.ActionMenuID);
                        // A named list for another class (a Visiting Mentor's
                        // druid line shown to a shaman) is hidden on purpose:
                        // the mentor offers one line per missing class and each
                        // player sees only its own. Hidden here, quietly, so the
                        // stock check below doesn't log it as "requested wrong
                        // gossip menu" (it did, twice per mentor greeting, until
                        // 2026-10-22; the owner: "I'd rather fix it instead of
                        // quiet it"). A list that doesn't exist still falls
                        // through to the stock check and its error.
                        if (trainer && !trainer->IsTrainerValidForPlayer(this))
                        {
                            canTalk = false;
                            break;                  // out of the option-type switch; the line is not added
                        }
                    }
CPP
    _b029_replace_line "${GOSSIP_CPP}" '                    Trainer::Trainer const* trainer = sObjectMgr->GetTrainer(creature->GetEntry());' "${T}/8" || return 1
    cat > "${T}/9" << 'CPP'
        {
            Creature* trainerNpc = source->ToCreature();
            uint32 listOverride = (trainerNpc && !sObjectMgr->GetTrainer(trainerNpc->GetEntry()))
                                  ? menuItemData->GossipActionMenuId : 0;
            GetSession()->SendTrainerList(trainerNpc, listOverride);
        }
CPP
    _b029_replace_line "${GOSSIP_CPP}" '            GetSession()->SendTrainerList(source->ToCreature());' "${T}/9" || return 1

    rm -rf "${T}"
}

unpatch_B029_gossip_option_trainer_list() {
    local f
    for f in \
        "${AC_CODE_DIR}/src/server/game/Globals/ObjectMgr.h" \
        "${AC_CODE_DIR}/src/server/game/Globals/ObjectMgr.cpp" \
        "${AC_CODE_DIR}/src/server/game/Server/WorldSession.h" \
        "${AC_CODE_DIR}/src/server/game/Handlers/NPCHandler.cpp" \
        "${AC_CODE_DIR}/src/server/game/Entities/Player/PlayerGossip.cpp"; do
        [[ -f "${f}" ]] || continue
        grep -q "B029-gossip-option-trainer" "${f}" || continue
        awk '
            /\/\/ >>> B029-gossip-option-trainer BEGIN/ { inblock = 1; next }
            inblock && /^\/\/B029-ORIG:/              { print substr($0, 13); next }   # 12 = length("//B029-ORIG:")
            inblock && /\/\/ <<< B029-gossip-option-trainer END/ { inblock = 0; next }
            inblock                                    { next }
            { print }' "${f}" > "${f}.b029" && mv "${f}.b029" "${f}"
    done
    return 0
}
