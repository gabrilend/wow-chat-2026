#!/usr/bin/env bash
# B028 - Basic: new characters spawn in their faction's rotating starting valley
# Issue 155d.
#
# For a general audience: on the basic profile a new character is not sent
# to its own race's starting valley. Each faction has four valleys, and the
# faction's "current" valley changes after every 30 new characters, in a
# shuffled order that visits every valley once per cycle of four. So the
# next 30 Alliance players all begin together in, say, Northshire, the next
# 30 in Shadowglen, and so on; the Horde does the same with its own four.
#
# How: the character-creation handler (the path real accounts use) is given
# a small block that runs after the character object is built and before it
# is first saved. It picks the valley, moves the new character there, writes
# its hearthstone home point there, and records the rotation's new state in
# the same database transaction that saves the character. Bots are created by
# the bot module through a different path, so they never enter the rotation
# (the issue's proposal: only characters made by real accounts count).
# Death knights are skipped: they start in Acherus (issue 718).
#
# Rotation state lives in the characters database, table
# basic_starting_valley_rotation (created and seeded by E023). The server
# keeps a copy in memory after the first read, so two characters created in
# the same moment cannot both read a stale count. A missing table or row
# refuses the creation with an error rather than quietly using the race's
# own valley.
#
# Only listed for the basic profile in patches/patches.sh.
# Parallelizable: Yes (unique file: CharacterHandler.cpp)

# {{{ patch_B028_basic_starting_valley_rotation
patch_B028_basic_starting_valley_rotation() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/CharacterHandler.cpp"
    if [[ ! -f "${FILE}" ]]; then
        echo "  [B028] ERROR: ${FILE} not found"
        return 1
    fi

    # Idempotent: both injected blocks carry unique markers.
    grep -q "B028-basic-valley-rotation" "${FILE}" && return 0

    # Anchors, checked before touching anything so a moved upstream line
    # stops the patch with a message instead of a half-applied file.
    local ANCHOR_FN='^void WorldSession::HandleCharCreateOpcode(WorldPacket& recvData)$'
    local ANCHOR_CALL='CharacterDatabaseTransaction characterTransaction = CharacterDatabase.BeginTransaction();'
    if ! grep -q "${ANCHOR_FN}" "${FILE}"; then
        echo "  [B028] ERROR: anchor not found (HandleCharCreateOpcode definition) in ${FILE}"
        return 1
    fi
    if [[ "$(grep -c "${ANCHOR_CALL}" "${FILE}")" -ne 1 ]]; then
        echo "  [B028] ERROR: expected exactly one '${ANCHOR_CALL}' in ${FILE}"
        return 1
    fi

    echo "  [B028] CharacterHandler: basic starting-valley rotation (155d)"

    # Block 1: the rotation itself, placed just above the handler.
    local HELPER
    HELPER="$(mktemp)"
    cat > "${HELPER}" << 'CPP_B028_HELPER'
// >>> B028-basic-valley-rotation-helper (155d) BEGIN
// Rotating faction starting valleys for the basic profile (issue 155d).
// Each faction's current valley holds for BATCH_SIZE new characters, then
// the next one is drawn from a shuffled bag of the four; the bag refills
// when empty, and the first draw of a refill never repeats the last valley.
// State is persisted in characters.basic_starting_valley_rotation and
// cached here after the first read (all creation runs on the world thread).
#include "Containers.h"
namespace BasicValleyRotation
{
    struct Valley
    {
        char const* name;
        uint32 mapId;
        uint32 zoneId;
        float  x, y, z, o;
    };

    // [team][index]; team = TEAM_ALLIANCE (0) / TEAM_HORDE (1). Coordinates
    // are the stock playercreateinfo values for each valley's native races.
    static Valley const VALLEYS[2][4] =
    {
        {
            { "Northshire Valley",   0,   12, -8949.95f,   -132.493f,  83.5312f, 0.0f     },
            { "Coldridge Valley",    0,    1, -6240.32f,    331.033f, 382.758f,  6.17716f },
            { "Shadowglen",          1,  141, 10311.3f,     832.463f, 1326.41f,  5.69632f },
            { "Ammen Vale",        530, 3526, -3961.64f, -13931.2f,   100.615f,  2.08364f },
        },
        {
            { "Valley of Trials",    1,   14,  -618.518f, -4251.67f,   38.718f,  0.0f     },
            { "Deathknell",          0,   85,  1676.71f,   1678.31f,  121.67f,   2.70526f },
            { "Camp Narache",        1,  215, -2917.58f,   -257.98f,   52.9968f, 0.0f     },
            { "Sunstrider Isle",   530, 3431, 10349.6f,   -6357.29f,   33.4026f, 5.31605f },
        },
    };

    static constexpr uint32 BATCH_SIZE    = 30;
    static constexpr uint8  NO_VALLEY_YET = 255;   // seeded value: draw on first use

    struct FactionState
    {
        bool               loaded  = false;
        uint8              current = NO_VALLEY_YET;
        uint32             count   = 0;             // characters placed in `current`
        std::vector<uint8> bag;                     // valleys left in this cycle
    };
    static FactionState s_state[2];

    // Read one faction's row. Returns false (and logs why) if the table or
    // row is missing: E023 was not applied to this characters database.
    static bool Load(uint8 team)
    {
        FactionState& st = s_state[team];
        QueryResult result = CharacterDatabase.Query(
            "SELECT current_valley, count_in_batch, bag FROM basic_starting_valley_rotation WHERE team = {}", team);
        if (!result)
        {
            LOG_ERROR("entities.player.character",
                "B028: no basic_starting_valley_rotation row for team {} — was E023 applied to this characters database? "
                "Character creation refused rather than falling back to the race's own valley.", team);
            return false;
        }
        Field* f   = result->Fetch();
        st.current = f[0].Get<uint8>();
        st.count   = f[1].Get<uint32>();
        st.bag.clear();
        // Keep the text in a named string: Tokenize returns views into it,
        // and a temporary would be destroyed before the loop body runs.
        std::string const bagText = f[2].Get<std::string>();
        for (std::string_view token : Acore::Tokenize(bagText, ',', false))
            if (Optional<uint8> v = Acore::StringTo<uint8>(token); v && *v < 4)
                st.bag.push_back(*v);
        st.loaded = true;
        return true;
    }

    // Advance the faction's rotation by one character and return the valley
    // that character gets. Appends the new state to `trans`, so it commits
    // or fails together with the character row.
    static Valley const* Next(uint8 team, CharacterDatabaseTransaction trans)
    {
        FactionState& st = s_state[team];
        if (!st.loaded && !Load(team))
            return nullptr;

        if (st.current == NO_VALLEY_YET || st.count >= BATCH_SIZE)
        {
            if (st.bag.empty())
            {
                st.bag = { 0, 1, 2, 3 };
                Acore::Containers::RandomShuffle(st.bag);
                // no valley twice in a row across the cycle boundary
                if (st.bag.front() == st.current)
                    std::swap(st.bag.front(), st.bag.back());
            }
            st.current = st.bag.front();
            st.bag.erase(st.bag.begin());
            st.count   = 0;
        }
        ++st.count;

        std::string bagText;
        for (uint8 v : st.bag)
            bagText += (bagText.empty() ? "" : ",") + std::to_string(v);
        trans->Append("UPDATE basic_starting_valley_rotation SET current_valley = {}, count_in_batch = {}, bag = '{}' WHERE team = {}",
            st.current, st.count, bagText, team);

        return &VALLEYS[team][st.current];
    }
}
// <<< B028-basic-valley-rotation-helper (155d) END
CPP_B028_HELPER

    # Block 2: the call, right after the creation transaction opens and
    # before the character is first saved.
    local CALL
    CALL="$(mktemp)"
    cat > "${CALL}" << 'CPP_B028_CALL'
                        // >>> B028-basic-valley-rotation-call (155d) BEGIN
                        // Death knights keep Acherus (issue 718). Everyone
                        // else goes to their faction's current valley, with
                        // the hearthstone bound there too.
                        if (newChar->getClass() != CLASS_DEATH_KNIGHT)
                        {
                            uint8 team = uint8(newChar->GetTeamId(true));
                            BasicValleyRotation::Valley const* valley = BasicValleyRotation::Next(team, characterTransaction);
                            if (!valley)
                            {
                                SendCharCreate(CHAR_CREATE_ERROR);
                                return;
                            }
                            if (newChar->GetMapId() != valley->mapId)
                            {
                                newChar->ResetMap();
                                newChar->SetMap(sMapMgr->CreateMap(valley->mapId, newChar.get()));
                            }
                            newChar->Relocate(valley->x, valley->y, valley->z, valley->o);

                            CharacterDatabasePreparedStatement* bindStmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_PLAYER_HOMEBIND);
                            bindStmt->SetData(0, newChar->GetGUID().GetCounter());
                            bindStmt->SetData(1, valley->mapId);    // uint32, as Player's own homebind write
                            bindStmt->SetData(2, uint16(valley->zoneId)); // uint16, as m_homebindAreaId
                            bindStmt->SetData(3, valley->x);
                            bindStmt->SetData(4, valley->y);
                            bindStmt->SetData(5, valley->z);
                            characterTransaction->Append(bindStmt);

                            LOG_INFO("entities.player.character", "B028: {} ({}) starts in {} (team {})",
                                newChar->GetName(), newChar->GetGUID().ToString(), valley->name, team);
                        }
                        // <<< B028-basic-valley-rotation-call (155d) END
CPP_B028_CALL

    # Block 1 goes on the line above the handler's definition ("r" appends
    # after a line, so append after the line before it). Block 2 goes after
    # the transaction line. The helper is inserted first; the call anchor is
    # looked up afterward, so its line number already accounts for it.
    local fn_line
    fn_line=$(grep -n "${ANCHOR_FN}" "${FILE}" | cut -d: -f1)
    sed -i "$((fn_line - 1))r ${HELPER}" "${FILE}"

    local call_line
    call_line=$(grep -n "${ANCHOR_CALL}" "${FILE}" | cut -d: -f1)
    sed -i "${call_line}r ${CALL}" "${FILE}"

    rm -f "${HELPER}" "${CALL}"

    # Verify both blocks landed exactly once.
    if [[ "$(grep -c 'B028-basic-valley-rotation-helper (155d) BEGIN' "${FILE}")" -ne 1 ||
          "$(grep -c 'B028-basic-valley-rotation-call (155d) BEGIN' "${FILE}")" -ne 1 ]]; then
        echo "  [B028] ERROR: blocks did not land exactly once in ${FILE}"
        return 1
    fi
}
# }}}

# {{{ unpatch_B028_basic_starting_valley_rotation
unpatch_B028_basic_starting_valley_rotation() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/CharacterHandler.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    grep -q "B028-basic-valley-rotation" "${FILE}" || return 0

    sed -i '/>>> B028-basic-valley-rotation-helper (155d) BEGIN/,/<<< B028-basic-valley-rotation-helper (155d) END/d' "${FILE}"
    sed -i '/>>> B028-basic-valley-rotation-call (155d) BEGIN/,/<<< B028-basic-valley-rotation-call (155d) END/d' "${FILE}"
    echo "  [B028] Reverted basic starting-valley rotation"
}
# }}}
