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

    # Strategy files - InitTriggers triggers parameter
    # REMOVED 2026-05-19. The patch commented out `triggers` as unused, but
    # upstream filled in InitTriggers bodies for NonCombatStrategy,
    # CombatStrategy, and DuelStrategy — those now USE triggers.push_back(...).
    # The patch broke the build at 74% with "use of undeclared identifier
    # 'triggers'" at CombatStrategy.cpp:12. Three other Strategy files
    # (FollowMasterStrategy, GuardStrategy, RTSCStrategy) still have empty
    # InitTriggers bodies — they will emit unused-parameter warnings, but
    # those don't break the build under current compiler flags. If they
    # ever do, restore this loop scoped to just those three files.

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
    #
    # 2026-05-19: extended to target the specific three Check() overrides
    # whose body uses AI_VALUE2 (context used via macro) but never touches
    # botAI: HealthChecker, ManaChecker, ItemCountChecker. The other Check
    # bodies (DistanceChecker, HunterChecker) already use botAI directly,
    # so the class-anchored ranges below skip them.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ReadyCheckAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/PlayerbotAI\* botAI)/PlayerbotAI* \/*botAI*\/)/' "${FILE}" 2>/dev/null || true
        sed -i 's/Event& event)/Event\& \/*event*\/)/' "${FILE}" 2>/dev/null || true
        sed -i '/class HealthChecker/,/class ManaChecker/ s|bool Check(PlayerbotAI\* botAI, AiObjectContext\* context)|bool Check(PlayerbotAI* /*botAI*/, AiObjectContext* context)|' "${FILE}" 2>/dev/null || true
        sed -i '/class ManaChecker/,/class DistanceChecker/ s|bool Check(PlayerbotAI\* botAI, AiObjectContext\* context)|bool Check(PlayerbotAI* /*botAI*/, AiObjectContext* context)|' "${FILE}" 2>/dev/null || true
        sed -i '/class ItemCountChecker/,/^};/ s|bool Check(PlayerbotAI\* botAI, AiObjectContext\* context)|bool Check(PlayerbotAI* /*botAI*/, AiObjectContext* context)|' "${FILE}" 2>/dev/null || true
    fi

    # MailAction.cpp — REMOVED 2026-05-20. Upstream already commented out the
    # unused `index` parameter in TakeMailProcessor, DeleteMailProcessor, and
    # ReadMailProcessor. The fourth processor (TellMailProcessor) USES `index`
    # at line 32 and must keep its parameter name. The previous sed had no
    # class anchor, so it clobbered TellMailProcessor's parameter — line 32
    # then failed to compile because `index` resolved to POSIX `::index()`
    # from <strings.h> (arithmetic on a function pointer). The unpatch sed
    # was also unanchored and over-restored the three upstream `/*index*/`
    # lines back to `index`, leaving three lines of drift each round trip.
    # No replacement needed: this entire section was treating a warning
    # that upstream already fixed. The 1:1-targeting rule established
    # 2026-05-20 (one sed per actual error, exact-inverse unpatch) would
    # have prevented this from being written.

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
    # LfgJoinAction::Execute takes Event by value (no &), so the `Event&`
    # selector above misses. Add the value variant explicitly.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/LfgActions.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/Event& event)/Event\& \/*event*\/)/' "${FILE}" 2>/dev/null || true
        sed -i 's|LfgJoinAction::Execute(Event event)|LfgJoinAction::Execute(Event /*event*/)|' "${FILE}" 2>/dev/null || true
    fi

    # CheckMountStateAction.cpp - mountData (only unused parameter; master is used)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/CheckMountStateAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|const MountData\& mountData|const MountData\& /*mountData*/|' "${FILE}" 2>/dev/null || true
    fi

    # --- 2026-05-19: additional sites from the post-build sweep. Each is
    # anchored on a unique enough signature substring to avoid colliding
    # with same-name parameters in adjacent overloads.

    # NewRpgBaseAction.cpp:226 - center is unused (moveStep and priority are used)
    FILE="${PLAYERBOTS_DIR}/Ai/World/Rpg/Action/NewRpgBaseAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|MoveRandomNear(float moveStep, MovementPriority priority, WorldObject\* center)|MoveRandomNear(float moveStep, MovementPriority priority, WorldObject* /*center*/)|' "${FILE}" 2>/dev/null || true
    fi

    # NewRpgOutdoorPvP.cpp:5 - event taken by value, ignored in body
    FILE="${PLAYERBOTS_DIR}/Ai/World/Rpg/Action/NewRpgOutdoorPvP.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|NewRpgOutdoorPvpAction::Execute(Event event)|NewRpgOutdoorPvpAction::Execute(Event /*event*/)|' "${FILE}" 2>/dev/null || true
    fi

    # RandomPlayerbotMgr.cpp:2024 - teleZ at end of signature; 2365 - handler
    FILE="${PLAYERBOTS_DIR}/Bot/RandomPlayerbotMgr.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|float teleX, float teleY, float teleZ)|float teleX, float teleY, float /*teleZ*/)|' "${FILE}" 2>/dev/null || true
        sed -i 's|HandlePlayerbotConsoleCommand(ChatHandler\* handler, char const\* args)|HandlePlayerbotConsoleCommand(ChatHandler* /*handler*/, char const* args)|' "${FILE}" 2>/dev/null || true
    fi

    # RaidSSCActions.cpp:2340 designatedLooter; 2405 firstCorePasser (in a
    # different overload that also has firstCorePasser). The second sed
    # anchors on the trailing `Player* secondCorePasser,` so it only
    # matches the 2405 occurrence.
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/SerpentshrineCavern/Action/RaidSSCActions.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|Player\* designatedLooter,|Player* /*designatedLooter*/,|' "${FILE}" 2>/dev/null || true
        sed -i 's|Player\* firstCorePasser, Player\* secondCorePasser,|Player* /*firstCorePasser*/, Player* secondCorePasser,|' "${FILE}" 2>/dev/null || true
    fi

    # TravelMgr.cpp:543 entry; 3839 amount (the amount sig is multi-line so
    # we use sed -z to span the newline). The getNextPoint signature is
    # the only place a `uint32 amount` parameter sits on its own line
    # right after `std::vector<WorldPosition*> points,` — anchor on that
    # neighbour so unrelated `uint32 amount` parameters elsewhere are
    # untouched.
    FILE="${PLAYERBOTS_DIR}/Mgr/Travel/TravelMgr.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|WorldPosition::getTransports(uint32 entry)|WorldPosition::getTransports(uint32 /*entry*/)|' "${FILE}" 2>/dev/null || true
        sed -i -z 's|getNextPoint(WorldPosition\* center, std::vector<WorldPosition\*> points,\n                                                    uint32 amount)|getNextPoint(WorldPosition* center, std::vector<WorldPosition*> points,\n                                                    uint32 /*amount*/)|' "${FILE}" 2>/dev/null || true
    fi

    # PlayerbotCommandScript.cpp:75 - HandlePerfMonCommand's handler is
    # unused; args is used.
    FILE="${PLAYERBOTS_DIR}/Script/PlayerbotCommandScript.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|HandlePerfMonCommand(ChatHandler\* handler, char const\* args)|HandlePerfMonCommand(ChatHandler* /*handler*/, char const* args)|' "${FILE}" 2>/dev/null || true
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

    # Strategy files — apply-side loop was removed 2026-05-19 (see apply
    # block above). No revert needed; nothing to undo.

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

    # MailAction.cpp — apply-side removed 2026-05-20 (see apply block above).
    # Unpatch also removed: the inverse sed was global and over-restored
    # upstream's own `/*index*/` comments to `index`, corrupting clean source
    # on every round trip. Nothing to undo.

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
