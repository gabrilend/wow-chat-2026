#!/usr/bin/env bash

B057_TAG='B057-view-distance-limit'
B057_DEFINE_ANCHOR='#define MAX_VISIBILITY_DISTANCE      250.0f                 // max distance for visible objects, experimental'
B057_INCLUDE_ANCHOR='#include "World.h"'
B057_READ_ANCHOR='    //visibility on continents'
B057_INSTANCE_ANCHOR='    m_VisibleDistance = World::GetMaxVisibleDistanceInInstances();'
B057_CONF_ANCHOR='Visibility.Distance.BGArenas = 250'

b057_insert() {
    local file="$1" anchor="$2" block="$3" where="$4"
    local count
    count=$(grep -cxF -- "${anchor}" "${file}" || true)
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B057] ERROR: expected exactly one '${anchor}' in ${file}, found ${count} (stale patch)"
        return 1
    fi
    ANCHOR="${anchor}" BLOCK="${block}" WHERE="${where}" awk '
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "before" { print ENVIRON["BLOCK"] }
        { print }
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "after" { print ENVIRON["BLOCK"] }' \
        "${file}" > "${file}.b057" && mv "${file}.b057" "${file}"
}

patch_B057_view_distance_limit_as_a_setting() {
    local DEF="${AC_CODE_DIR}/src/server/game/Entities/Object/ObjectDefines.h"
    local WORLD="${AC_CODE_DIR}/src/server/game/World/World.cpp"
    local MAP="${AC_CODE_DIR}/src/server/game/Maps/Map.cpp"
    local CONF="${AC_CODE_DIR}/src/server/apps/worldserver/worldserver.conf.dist"
    local f
    for f in "${DEF}" "${WORLD}" "${MAP}" "${CONF}"; do
        [[ -f "${f}" ]] || { echo "  [B057] ERROR: ${f} missing"; return 1; }
    done
    grep -qF "${B057_TAG}" "${DEF}" && return 0                  # witness guard

    b057_insert "${DEF}" "${B057_DEFINE_ANCHOR}" \
"// >>> ${B057_TAG} BEGIN
// The most any view distance may be is a setting (Visibility.Distance.Max,
// read in World.cpp at start; 250 if unset), no longer the fixed 250 above;
// and whether the instances that force their own distance keep it
// (Visibility.Distance.InstanceOverrides). Issue 195.
#undef MAX_VISIBILITY_DISTANCE
extern float gMaxVisibilityDistance;
extern bool gVisibilityInstanceOverrides;
#define MAX_VISIBILITY_DISTANCE gMaxVisibilityDistance
// <<< ${B057_TAG} END" after || return 1

    b057_insert "${WORLD}" "${B057_INCLUDE_ANCHOR}" \
"// >>> ${B057_TAG} BEGIN
float gMaxVisibilityDistance = 250.0f;          // Visibility.Distance.Max (issue 195)
bool gVisibilityInstanceOverrides = true;       // Visibility.Distance.InstanceOverrides
// <<< ${B057_TAG} END" after || return 1

    b057_insert "${WORLD}" "${B057_READ_ANCHOR}" \
"    // >>> ${B057_TAG} BEGIN
    // The most any view distance may be, read before the clamps below use it.
    // Not more than 0: an error, and the stock 250.
    gMaxVisibilityDistance = sConfigMgr->GetOption<float>(\"Visibility.Distance.Max\", 250.0f);
    if (gMaxVisibilityDistance <= 0.0f)
    {
        LOG_ERROR(\"server.loading\", \"Visibility.Distance.Max must be more than 0; using 250\");
        gMaxVisibilityDistance = 250.0f;
    }
    gVisibilityInstanceOverrides = sConfigMgr->GetOption<bool>(\"Visibility.Distance.InstanceOverrides\", true);
    // <<< ${B057_TAG} END" before || return 1

    b057_insert "${MAP}" "${B057_INSTANCE_ANCHOR}" \
"    // >>> ${B057_TAG} BEGIN
    // Visibility.Distance.InstanceOverrides = 0: no instance forces its own
    // distance; every one sees as far as Visibility.Distance.Instances says.
    if (!gVisibilityInstanceOverrides)
        return;
    // <<< ${B057_TAG} END" after || return 1

    b057_insert "${CONF}" "${B057_CONF_ANCHOR}" \
"# >>> ${B057_TAG} BEGIN

#
#    Visibility.Distance.Max
#        Description: The most any of the three distances above may be (issue 195).
#                     Higher lets them go higher, and loads the map farther round
#                     each player to match: more memory and update time per player.
#                     Bots never see farther than they act, whatever this is (B056).
#        Default:     250 - (the old fixed limit)

Visibility.Distance.Max = 250

#
#    Visibility.Distance.InstanceOverrides
#        Description: Whether the dungeons and raids that force their own view
#                     distance keep it (150-200 in several Wrath raids and
#                     dungeons, 175 in Dire Maul, the Eye and the Oculus, 300 in
#                     Ahn'Qiraj's temple).
#        Default:     1 - (they keep it, stock)
#                     0 - (every instance sees Visibility.Distance.Instances)

Visibility.Distance.InstanceOverrides = 1
# <<< ${B057_TAG} END" after || return 1
}

unpatch_B057_view_distance_limit_as_a_setting() {
    local f
    for f in "${AC_CODE_DIR}/src/server/game/Entities/Object/ObjectDefines.h" \
             "${AC_CODE_DIR}/src/server/game/World/World.cpp" \
             "${AC_CODE_DIR}/src/server/game/Maps/Map.cpp" \
             "${AC_CODE_DIR}/src/server/apps/worldserver/worldserver.conf.dist"; do
        [[ -f "${f}" ]] || continue
        grep -qF "${B057_TAG}" "${f}" || continue                 # nothing of ours
        awk '
            /(\/\/|#) >>> B057-view-distance-limit BEGIN/ { inblock = 1; next }
            inblock && /(\/\/|#) <<< B057-view-distance-limit END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b057" && mv "${f}.b057" "${f}"
    done
    return 0
}
