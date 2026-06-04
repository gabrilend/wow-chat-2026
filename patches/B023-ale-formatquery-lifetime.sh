#!/usr/bin/env bash
# B023-ale-formatquery-lifetime.sh
# Fixes a dangling-pointer bug in ALE's sync DB query methods. When a Lua
# caller passes format args after the query string (numArgs > 1), the
# upstream code does:
#
#     query = ALE::FormatQuery(L, query).c_str();
#
# `FormatQuery` returns std::string by value. `.c_str()` points into that
# temporary. The temporary is destroyed at the end of the statement. The
# next line passes the now-dangling pointer to WorldDatabase.Query() (or
# CharDatabase, AuthDatabase). Undefined behaviour, observed in practice
# as buffer corruption — which is why the predecessor src/lua/ambush.lua
# cached creature data at startup instead of querying with format args.
#
# This fix wraps the buggy two-line snippet in a marker-bounded block
# that uses a properly-scoped std::string to keep the buffer alive
# through the subsequent Database.Query() call. Six call sites in
# GlobalMethods.h share an identical buggy shape, so one anchored sed
# transforms all six.
#
# See issues/141-ale-formatquery-dangling-pointer.md for the full
# diagnosis. Worth submitting upstream — see
# docs/patches/contributing-upstream.md for the workflow.

# {{{ patch_B023_ale_formatquery_lifetime
patch_B023_ale_formatquery_lifetime() {
    local SRC="${AC_CODE_DIR}"
    local FILE="${SRC}/modules/mod-ale/src/LuaEngine/methods/GlobalMethods.h"

    [[ -f "${FILE}" ]] || return 0

    # All six call sites share this exact two-line shape (verified by
    # `grep -B1 'query = ALE::FormatQuery'` returning 6 identical hunks).
    # The substitution is global; one apply handles all six.
    sed -i -z 's|        if (numArgs > 1)\n            query = ALE::FormatQuery(L, query)\.c_str();|        // {{{ B023-formatquery-lifetime\n        std::string formattedQuery;\n        if (numArgs > 1)\n        {\n            formattedQuery = ALE::FormatQuery(L, query);\n            query = formattedQuery.c_str();\n        }\n        // }}} B023-formatquery-lifetime|g' "${FILE}"
}
# }}}

# {{{ unpatch_B023_ale_formatquery_lifetime
unpatch_B023_ale_formatquery_lifetime() {
    local SRC="${AC_CODE_DIR}"
    local FILE="${SRC}/modules/mod-ale/src/LuaEngine/methods/GlobalMethods.h"

    [[ -f "${FILE}" ]] || return 0

    # Inverse of the apply: locate the marker-bounded block (which only
    # this patch ever inserts) and substitute back to the original two
    # lines. The marker `B023-formatquery-lifetime` inside the matched
    # text means this can never false-match upstream or any other patch.
    sed -i -z 's|        // {{{ B023-formatquery-lifetime\n        std::string formattedQuery;\n        if (numArgs > 1)\n        {\n            formattedQuery = ALE::FormatQuery(L, query);\n            query = formattedQuery.c_str();\n        }\n        // }}} B023-formatquery-lifetime|        if (numArgs > 1)\n            query = ALE::FormatQuery(L, query).c_str();|g' "${FILE}"
}
# }}}
