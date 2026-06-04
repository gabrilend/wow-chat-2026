#!/usr/bin/env bash
# C019 - RealmID per profile
# Each profile owns one row in the unified acore_auth.realmlist table
# (issue 136a). The worldserver picks "its" row by matching
# `worldserver.conf:RealmID` against the row's `id` column. This patch
# writes the per-profile id into the conf so the active worldserver
# answers for its row only.
#
# Profile ↔ RealmID mapping must stay in sync with
# scripts/set-active-realm (which seeds the same id range into
# acore_auth.realmlist) — both files are the source of truth for the
# numbering. Update them as a pair.
#
# Profiles: all
# Alpha is included even though it uses isolated auth (its own RealmID
# in its own acore_auth_alpha.realmlist row); the mapping below assigns
# 4 for symmetry. If alpha's auth ever merges with the unified table,
# no code change is needed.

# -- {{{ config_realm_id
config_realm_id() {
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    local REALM_ID
    case "${PROFILE}" in
        release)  REALM_ID=1 ;;
        beta)     REALM_ID=2 ;;
        vanilla)  REALM_ID=3 ;;
        alpha)    REALM_ID=4 ;;
        *)
            echo "ERROR: Unknown profile '${PROFILE}' in config_realm_id"
            return 1
            ;;
    esac

    sed -i 's|^RealmID.*=.*|RealmID = '"${REALM_ID}"'|' "${conf_world}"
}
CONFIG_PROFILES[config_realm_id]="all"
CONFIG_DESCRIPTIONS[config_realm_id]="RealmID per profile (1=release, 2=beta, 3=vanilla, 4=alpha)"
# -- }}}
