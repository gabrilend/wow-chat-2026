#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C001
# profiles:   all
# priority:   1100
# kind:       settings
# about:      Database Connections
# ==== end of header ====
# C001 - Database Connections
# Set database connection strings (project-specific)
# Profiles: all

# -- {{{ config_database_connections
config_database_connections() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    # Database isolation policy (revised by 136a — unified-realmlist):
    #   - Release, Beta, and Vanilla share `acore_auth` so the user's account
    #       and the realmlist table are visible from every profile. The realm
    #       list shows one row per profile; flag column gates which is "online".
    #       World / characters / playerbots STAY per-profile so the actual
    #       game data never crosses profiles:
    #         release      : acore_world / acore_characters / acore_playerbots
    #         beta         : acore_world_beta / acore_characters_beta /
    #                        acore_playerbots_beta (its own since 2026-10-17, 136b)
    #         vanilla      : acore_world_vanilla / acore_characters_vanilla /
    #                        acore_playerbots_vanilla
    #   - Alpha is wholly isolated (different source, different schema, different era):
    #       port 3308, databases acore_auth_alpha / acore_world_alpha / acore_characters_alpha
    #
    # The rationale: release is the most up-to-date public target, alpha is the holiday
    # relic running an old AzerothCore. Their schemas are incompatible. Sharing a port
    # or any database between them risks cross-version contamination. Beta shares
    # release's source (source-beta) and so its schema, but since 2026-10-17 not its
    # data: sharing let beta's install steps change release's world (issue 136b).
    #
    # IMPLEMENTATION NOTE: Alpha on port 3308 requires either (a) a second MySQL instance
    # bound to 3308, or (b) the project-local MySQL configured to listen on both 3307
    # and 3308. The current mysql/ install only listens on 3307. See follow-up issue
    # for the alpha-mysql-instance work.
    local DB_HOST="127.0.0.1"
    local DB_PORT
    local DB_AUTH
    local DB_WORLD
    local DB_CHARS
    local DB_PLAYERBOTS
    case "${PROFILE}" in
        release)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world"
            DB_CHARS="acore_characters"
            DB_PLAYERBOTS="acore_playerbots"
            ;;
        beta)
            # beta (136b, 2026-10-17): its own world, characters and
            # playerbots. Until then beta shared release's, so beta's
            # destructive install steps (E012 clears creatures) emptied
            # release's world, and characters crossed between the two.
            # Must match _profile_db_name in patches/E-helpers.sh, which
            # the install uses to create and seed them;
            # scripts/test-profile-config-gates checks the two agree.
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_beta"
            DB_CHARS="acore_characters_beta"
            DB_PLAYERBOTS="acore_playerbots_beta"
            ;;
        vanilla)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_vanilla"
            DB_CHARS="acore_characters_vanilla"
            DB_PLAYERBOTS="acore_playerbots_vanilla"
            ;;
        basic)
            # basic (155): its own world/characters/playerbots, seeded from a
            # fresh AzerothCore base (not from vanilla's, which carries the
            # starter-kit/pretrain/spawn-town rows basic leaves out).
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_basic"
            DB_CHARS="acore_characters_basic"
            DB_PLAYERBOTS="acore_playerbots_basic"
            ;;
        cc-test)
            # cc-test (176): the custom client's test server. Its own
            # world/characters/playerbots, seeded from a fresh AzerothCore
            # base, so test characters are made and wiped without touching
            # anyone's play. Underscores: a hyphen can't stand in an
            # unquoted database name.
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_cc_test"
            DB_CHARS="acore_characters_cc_test"
            DB_PLAYERBOTS="acore_playerbots_cc_test"
            ;;
        alpha)
            DB_PORT="3308"
            DB_AUTH="acore_auth_alpha"
            DB_WORLD="acore_world_alpha"
            DB_CHARS="acore_characters_alpha"
            DB_PLAYERBOTS=""  # alpha has no playerbots; field unused
            ;;
        *)
            echo "ERROR: Unknown profile '${PROFILE}' in config_database_connections"
            return 1
            ;;
    esac

    # Auth database (per-isolation-group, not literally shared between release and alpha)
    sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_AUTH}"'"|' "${conf_auth}"
    sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo     = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_AUTH}"'"|' "${conf_world}"

    # World database
    sed -i 's|^WorldDatabaseInfo.*=.*|WorldDatabaseInfo     = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_WORLD}"'"|' "${conf_world}"

    # Character database
    sed -i 's|^CharacterDatabaseInfo.*=.*|CharacterDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_CHARS}"'"|' "${conf_world}"

    # Playerbots database (module config — only present for profiles with mod-playerbots)
    local conf_playerbots="${INSTALL_DIR}/etc/modules/playerbots.conf"
    if [[ -f "${conf_playerbots}" && -n "${DB_PLAYERBOTS}" ]]; then
        sed -i 's|^PlayerbotsDatabaseInfo.*=.*|PlayerbotsDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_PLAYERBOTS}"'"|' "${conf_playerbots}"
    fi
}
CONFIG_PROFILES[config_database_connections]="all"
CONFIG_DESCRIPTIONS[config_database_connections]="Database connections (MySQL credentials)"
# -- }}}
# ==== footer of C001 ====
# lines:      133
# ==== end of footer ====
