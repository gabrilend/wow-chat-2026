#!/usr/bin/env bash

patch_B030_basic_rules_script() {
    local SRC="${DIR}/src/cpp-basic/basic_rules.cpp"
    local DST="${AC_CODE_DIR}/src/server/scripts/Custom/basic_rules.cpp"
    local LOADER="${AC_CODE_DIR}/src/server/scripts/Custom/custom_script_loader.cpp"

    if [[ ! -f "${SRC}" ]]; then
        echo "  [B030] ERROR: rules source missing: ${SRC}"
        return 1
    fi
    if [[ ! -f "${LOADER}" ]]; then
        echo "  [B030] ERROR: stock Custom loader missing: ${LOADER}"
        return 1
    fi
    grep -q "B030-basic-rules" "${LOADER}" && [[ -f "${DST}" ]] && return 0

    local ANCHOR_DECL='// This is where scripts'"'"' loading functions should be declared:'
    local ANCHOR_FN='void AddCustomScripts()'
    if [[ "$(grep -cxF -- "${ANCHOR_DECL}" "${LOADER}")" -ne 1 || "$(grep -cxF -- "${ANCHOR_FN}" "${LOADER}")" -ne 1 ]]; then
        echo "  [B030] ERROR: loader anchors not found exactly once in ${LOADER}"
        return 1
    fi

    echo "  [B030] Custom scripts: basic's server rules (155g talent cap)"
    cp "${SRC}" "${DST}"

    ANCHOR_DECL="${ANCHOR_DECL}" ANCHOR_FN="${ANCHOR_FN}" awk '
        { print }
        $0 == ENVIRON["ANCHOR_DECL"] {
            print "// >>> B030-basic-rules BEGIN"
            print "void AddSC_basic_rules();"
            print "// <<< B030-basic-rules END"
        }
        infn && $0 == "{" {
            print "    // >>> B030-basic-rules BEGIN"
            print "    AddSC_basic_rules();"
            print "    // <<< B030-basic-rules END"
            infn = 0
        }
        $0 == ENVIRON["ANCHOR_FN"] { infn = 1 }
    ' "${LOADER}" > "${LOADER}.b030" && mv "${LOADER}.b030" "${LOADER}"

    if [[ "$(grep -c 'B030-basic-rules BEGIN' "${LOADER}")" -ne 2 ]]; then
        echo "  [B030] ERROR: loader blocks did not land exactly twice in ${LOADER}"
        return 1
    fi
}

unpatch_B030_basic_rules_script() {
    local DST="${AC_CODE_DIR}/src/server/scripts/Custom/basic_rules.cpp"
    local LOADER="${AC_CODE_DIR}/src/server/scripts/Custom/custom_script_loader.cpp"
    rm -f "${DST}"
    [[ -f "${LOADER}" ]] && sed -i '/>>> B030-basic-rules BEGIN/,/<<< B030-basic-rules END/d' "${LOADER}"
    return 0
}
