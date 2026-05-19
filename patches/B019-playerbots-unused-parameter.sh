#!/usr/bin/env bash
# B019-playerbots-unused-parameter.sh
# Fixes unused parameter warnings in mod-playerbots
#
# Warning: unused parameter 'X' [-Wunused-parameter]
#
# Fix: Comment out unused parameter names in function signatures
# This preserves the interface while suppressing the warning.
#
# Pattern: void foo(Type param) -> void foo(Type /*param*/)
#
# Note: This patch handles specific known cases. For comprehensive
# fixes, consider contributing to upstream with proper review.

# {{{ patch_B019_playerbots_unused_parameter
patch_B019_playerbots_unused_parameter() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    local FILE

    # Strategy files - InitTriggers with unused triggers parameter
    for f in NonCombatStrategy CombatStrategy DuelStrategy FollowMasterStrategy GuardStrategy RTSCStrategy; do
        FILE="${PLAYERBOTS_DIR}/Ai/Base/Strategy/${f}.cpp"
        if [[ -f "${FILE}" ]]; then
            sed -i 's/std::vector<TriggerNode\*>& triggers)/std::vector<TriggerNode*>\& \/*triggers*\/)/' "${FILE}" 2>/dev/null || true
        fi
    done

    # CombatStrategy - multipliers parameter
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Strategy/CombatStrategy.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/std::vector<Multiplier\*>& multipliers)/std::vector<Multiplier*>\& \/*multipliers*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # ChatCommandHandlerStrategy - botAI parameter
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Strategy/ChatCommandHandlerStrategy.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/PlayerbotAI\* botAI)/PlayerbotAI* \/*botAI*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # RacialsStrategy and UsePotionsStrategy - botAI
    for f in RacialsStrategy UsePotionsStrategy; do
        FILE="${PLAYERBOTS_DIR}/Ai/Base/Strategy/${f}.cpp"
        if [[ -f "${FILE}" ]]; then
            sed -i 's/PlayerbotAI\* botAI)/PlayerbotAI* \/*botAI*\/)/' "${FILE}" 2>/dev/null || true
        fi
    done

    # CastCustomSpellAction.h - target and spellInfo
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/CastCustomSpellAction.h"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/WorldObject\* target)/WorldObject* \/*target*\/)/' "${FILE}" 2>/dev/null || true
        sed -i 's/SpellInfo const\* spellInfo)/SpellInfo const* \/*spellInfo*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # MovementActions.cpp - multiple parameters
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/MovementActions.cpp"
    if [[ -f "${FILE}" ]]; then
        # Line 170: idle and react (both followed by comma, not paren)
        sed -i 's/, bool idle,/, bool \/*idle*\/,/' "${FILE}" 2>/dev/null || true
        sed -i 's/, bool react,/, bool \/*react*\/,/' "${FILE}" 2>/dev/null || true
        # Line 900 only: IsMovingAllowed - mapId, x, y, z (IsDuplicateMove at 913 uses x,y,z)
        sed -i 's/IsMovingAllowed(uint32 mapId, float x, float y, float z)/IsMovingAllowed(uint32 \/*mapId*\/, float \/*x*\/, float \/*y*\/, float \/*z*\/)/' "${FILE}" 2>/dev/null || true
        # Line 913: IsDuplicateMove - only mapId is unused, x,y,z are used
        sed -i 's/IsDuplicateMove(uint32 mapId,/IsDuplicateMove(uint32 \/*mapId*\/,/' "${FILE}" 2>/dev/null || true
        # Line 1289: ChaseTo angle only (Follow at 1113 uses angle)
        # Match the full signature including class prefix
        sed -i 's/MovementAction::ChaseTo(WorldObject\* obj, float distance, float angle)/MovementAction::ChaseTo(WorldObject* obj, float distance, float \/*angle*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # ReadyCheckAction.cpp - botAI, event
    # NOTE: do NOT comment out "AiObjectContext* context)". The file has 6
    # Check() overrides with that signature, and at least 4 use `context` via
    # the AI_VALUE2 macro (which expands to `context->GetValue<...>(...)`).
    # Commenting it out broke the build (2026-05-19) with "use of undeclared
    # identifier 'context'" at every AI_VALUE2 call site.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ReadyCheckAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/PlayerbotAI\* botAI)/PlayerbotAI* \/*botAI*\/)/' "${FILE}" 2>/dev/null || true
        sed -i 's/Event& event)/Event\& \/*event*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # MailAction.cpp - index parameter (3 instances)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/MailAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/, uint32 index)/, uint32 \/*index*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # SayAction files
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/SayAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/ObjectGuid guid2)/ObjectGuid \/*guid2*\/)/' "${FILE}" 2>/dev/null || true
        sed -i 's/std::string const& msg, std::string const& name)/std::string const\& \/*msg*\/, std::string const\& \/*name*\/)/' "${FILE}" 2>/dev/null || true
    fi
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/SayAction.h"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/Event& event)/Event\& \/*event*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # BankAction - bank parameter (Unit*, not GameObject* - GuildBankAction uses GameObject)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/BankAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/Unit\* bank)/Unit* \/*bank*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # LfgActions.cpp - event
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/LfgActions.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/Event& event)/Event\& \/*event*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # ChooseTravelTargetAction.cpp - onlyCompleted (2nd param, not at end)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ChooseTravelTargetAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/bool onlyCompleted, bool newQuests/bool \/*onlyCompleted*\/, bool newQuests/' "${FILE}" 2>/dev/null || true
    fi

    # ReleaseSpiritAction.cpp - isAutoRelease
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ReleaseSpiritAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/bool isAutoRelease)/bool \/*isAutoRelease*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # SeeSpellAction.cpp - lastWp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/SeeSpellAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/LastMovement& lastWp)/LastMovement\& \/*lastWp*\/)/' "${FILE}" 2>/dev/null || true
    fi

    # AutoMaintenanceOnLevelupAction.cpp - out (pointer, not reference)
    # Only LearnTrainerSpells - LearnQuestSpells actually uses out at lines 146, 151
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/AutoMaintenanceOnLevelupAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/LearnTrainerSpells(std::ostringstream\* out)/LearnTrainerSpells(std::ostringstream* \/*out*\/)/' "${FILE}" 2>/dev/null || true
    fi
}
# }}}

# {{{ unpatch_B019_playerbots_unused_parameter
unpatch_B019_playerbots_unused_parameter() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    local FILE

    # Strategy files - reverse triggers parameter
    for f in NonCombatStrategy CombatStrategy DuelStrategy FollowMasterStrategy GuardStrategy RTSCStrategy; do
        FILE="${PLAYERBOTS_DIR}/Ai/Base/Strategy/${f}.cpp"
        [[ -f "${FILE}" ]] && sed -i 's/std::vector<TriggerNode\*>& \/\*triggers\*\//std::vector<TriggerNode*>\& triggers/' "${FILE}" 2>/dev/null || true
    done

    # CombatStrategy - multipliers
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Strategy/CombatStrategy.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/std::vector<Multiplier\*>& \/\*multipliers\*\//std::vector<Multiplier*>\& multipliers/' "${FILE}" 2>/dev/null || true

    # ChatCommandHandlerStrategy - botAI
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Strategy/ChatCommandHandlerStrategy.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/PlayerbotAI\* \/\*botAI\*\//PlayerbotAI* botAI/' "${FILE}" 2>/dev/null || true

    # RacialsStrategy and UsePotionsStrategy - botAI
    for f in RacialsStrategy UsePotionsStrategy; do
        FILE="${PLAYERBOTS_DIR}/Ai/Base/Strategy/${f}.cpp"
        [[ -f "${FILE}" ]] && sed -i 's/PlayerbotAI\* \/\*botAI\*\//PlayerbotAI* botAI/' "${FILE}" 2>/dev/null || true
    done

    # CastCustomSpellAction.h
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/CastCustomSpellAction.h"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/WorldObject\* \/\*target\*\//WorldObject* target/' "${FILE}" 2>/dev/null || true
        sed -i 's/SpellInfo const\* \/\*spellInfo\*\//SpellInfo const* spellInfo/' "${FILE}" 2>/dev/null || true
    fi

    # MovementActions.cpp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/MovementActions.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/bool \/\*idle\*\/,/bool idle,/' "${FILE}" 2>/dev/null || true
        sed -i 's/bool \/\*react\*\/,/bool react,/' "${FILE}" 2>/dev/null || true
        sed -i 's/IsMovingAllowed(uint32 \/\*mapId\*\/, float \/\*x\*\/, float \/\*y\*\/, float \/\*z\*\/)/IsMovingAllowed(uint32 mapId, float x, float y, float z)/' "${FILE}" 2>/dev/null || true
        sed -i 's/IsDuplicateMove(uint32 \/\*mapId\*\//IsDuplicateMove(uint32 mapId/' "${FILE}" 2>/dev/null || true
        sed -i 's/MovementAction::ChaseTo(WorldObject\* obj, float distance, float \/\*angle\*\/)/MovementAction::ChaseTo(WorldObject* obj, float distance, float angle)/' "${FILE}" 2>/dev/null || true
    fi

    # ReadyCheckAction.cpp — matches the apply block; context handling removed
    # (see apply-side note above)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ReadyCheckAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/PlayerbotAI\* \/\*botAI\*\//PlayerbotAI* botAI/' "${FILE}" 2>/dev/null || true
        sed -i 's/Event& \/\*event\*\//Event\& event/' "${FILE}" 2>/dev/null || true
    fi

    # MailAction.cpp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/MailAction.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/uint32 \/\*index\*\//uint32 index/' "${FILE}" 2>/dev/null || true

    # SayAction files
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/SayAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/ObjectGuid \/\*guid2\*\//ObjectGuid guid2/' "${FILE}" 2>/dev/null || true
        sed -i 's/std::string const& \/\*msg\*\/, std::string const& \/\*name\*\//std::string const\& msg, std::string const\& name/' "${FILE}" 2>/dev/null || true
    fi
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/SayAction.h"
    [[ -f "${FILE}" ]] && sed -i 's/Event& \/\*event\*\//Event\& event/' "${FILE}" 2>/dev/null || true

    # BankAction
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/BankAction.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/Unit\* \/\*bank\*\//Unit* bank/' "${FILE}" 2>/dev/null || true

    # LfgActions.cpp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/LfgActions.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/Event& \/\*event\*\//Event\& event/' "${FILE}" 2>/dev/null || true

    # ChooseTravelTargetAction.cpp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ChooseTravelTargetAction.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/bool \/\*onlyCompleted\*\/, bool newQuests/bool onlyCompleted, bool newQuests/' "${FILE}" 2>/dev/null || true

    # ReleaseSpiritAction.cpp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ReleaseSpiritAction.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/bool \/\*isAutoRelease\*\//bool isAutoRelease/' "${FILE}" 2>/dev/null || true

    # SeeSpellAction.cpp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/SeeSpellAction.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/LastMovement& \/\*lastWp\*\//LastMovement\& lastWp/' "${FILE}" 2>/dev/null || true

    # AutoMaintenanceOnLevelupAction.cpp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/AutoMaintenanceOnLevelupAction.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/LearnTrainerSpells(std::ostringstream\* \/\*out\*\/)/LearnTrainerSpells(std::ostringstream* out)/' "${FILE}" 2>/dev/null || true
}
# }}}
