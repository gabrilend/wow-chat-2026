#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E017
# profiles:   beta
# priority:   1470
# kind:       install
# about:      Fixes upstream mod-playerbots migration ordering bug (the
# ==== end of header ====
# E017-beta-relocate-logout-texts.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E017_beta_relocate_logout_texts
# Fixes upstream mod-playerbots migration ordering bug (the
# 03_13/03_14/03_26 sequence has an ID conflict on bot_text rows).
# Targets acore_playerbots (shared with release).
#
# Snapshot-based revert: the apply source captures the two named rows
# from ai_playerbot_texts and ai_playerbot_texts_chance before
# renumbering. Revert restores from snapshot and drops the snapshot.
patch_E017_beta_relocate_logout_texts() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_playerbots/17-relocate-logout-texts.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_playerbots.src/17-relocate-logout-texts.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E017_APPLY" "${SQL_FILE}"; then
        echo "  [E017] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E017] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_playerbots" "$(_profile_db_name acore_playerbots)" || return 1

    echo "  [E017] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E017_beta_relocate_logout_texts() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_playerbots/17-relocate-logout-texts.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E017_REVERT" "${SQL_FILE}"; then
        echo "  [E017] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_playerbots" "$(_profile_db_name acore_playerbots)" || return 1

    echo "  [E017] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E017_REVERT beta-relocate-logout-texts
-- Revert-form: restore the two named rows in ai_playerbot_texts and
-- ai_playerbot_texts_chance from the snapshots the apply captured
-- before renumbering them. Snapshots are small (2-4 rows total).
DELETE FROM `ai_playerbot_texts`        WHERE `name` IN ('bot_not_your_master', 'bot_rndbot_no_logout');
DELETE FROM `ai_playerbot_texts_chance` WHERE `name` IN ('bot_not_your_master', 'bot_rndbot_no_logout');

INSERT INTO `ai_playerbot_texts`        SELECT * FROM `wow_chat_e017_snapshot_texts`;
INSERT INTO `ai_playerbot_texts_chance` SELECT * FROM `wow_chat_e017_snapshot_chance`;

DROP TABLE IF EXISTS `wow_chat_e017_snapshot_texts`;
DROP TABLE IF EXISTS `wow_chat_e017_snapshot_chance`;
SQL
}
# -- }}}
# ==== footer of E017 ====
# lines:      68
# ==== end of footer ====
