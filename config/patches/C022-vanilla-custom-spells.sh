#!/usr/bin/env bash
# C022 - Enable Custom Starting Spells (Vanilla)
# Set PlayerStart.CustomSpells to 1 so the engine actually reads the
# playercreateinfo_spell_custom table at character creation.
#
# Without this the table is inert. Player::LearnCustomSpells() opens with
#
#     if (!sWorld->getBoolConfig(CONFIG_START_CUSTOM_SPELLS))
#         return;
#
# at source-beta/src/server/game/Entities/Player/Player.cpp:11909, and
# everything that reads PlayerInfo::customSpells sits below that early
# return. The config constant binds to this key at
# source-beta/src/server/game/World/WorldConfig.cpp:550, defaulting to
# false, and AzerothCore's shipped worldserver.conf.dist sets it to 0.
#
# The consequence, found 2026-08-07 and written up as issue 148w: the
# vanilla profile's 717-row level-20 pretrain migration (148j) had never
# been read by anything, on any boot, since it was written. A level-20
# mage arrived with an empty spellbook and two weapon proficiencies —
# and those two came from the ALE first-login kit hook (148k), which is
# our own Lua and is not gated by this flag. 23,462 of 23,915 existing
# characters have no spells at all for the same reason.
#
# Nothing in the world database could reveal this. The pretrain rows are
# present, complete, and correctly masked; the data-side validator
# reported all checks green throughout. The gap was entirely between
# "the rows exist" and "anything reads them."
#
# Note this is creation-time only. The engine consults
# playercreateinfo_spell_custom when a character is made and never
# revisits it, so characters created before this patch lands stay empty
# and must be rerolled or topped up. See 148w for that decision.
#
# Profiles: vanilla

# -- {{{ config_vanilla_custom_spells
config_vanilla_custom_spells() {
    local KEY="PlayerStart.CustomSpells"
    local WANT=1
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    # Guard: the file has to be there. init_config() copies .dist to .conf
    # before this runs, so its absence means the pipeline stopped earlier.
    if [[ ! -f "${conf}" ]]; then
        echo "    [C022] ERROR: worldserver.conf not found"
        echo "           Looked for: ${conf}"
        echo "           INSTALL_DIR resolved to: ${INSTALL_DIR:-<unset>}"
        echo "           Did not complete: setting ${KEY} = ${WANT}"
        echo "           Completed before this: nothing — this is the first check"
        echo "           To debug: did init_config() run and copy the .dist"
        echo "           template? If INSTALL_DIR is empty the profile never"
        echo "           resolved, which would break every C-patch, not just"
        echo "           this one — check whether the others also failed."
        return 1
    fi

    # Guard: the key has to already be present. The substitution below
    # rewrites an existing line and cannot create a missing one, so a
    # key that upstream renamed or dropped would leave the config at its
    # default with no visible sign. That silent-default outcome is the
    # exact failure this patch exists to fix, so it errors instead.
    local found
    found="$(grep -c "^${KEY}[[:space:]]*=" "${conf}")"
    if [[ "${found}" -eq 0 ]]; then
        echo "    [C022] ERROR: key '${KEY}' not present in worldserver.conf"
        echo "           File: ${conf}"
        echo "           Matching lines found: ${found} (expected 1)"
        echo "           Did not complete: setting ${KEY} = ${WANT}"
        echo "           Completed before this: file-presence check passed"
        echo "           Most likely cause: upstream renamed or removed the"
        echo "           key. Grep WorldConfig.cpp for CONFIG_START_CUSTOM_SPELLS"
        echo "           to see what it binds to now — if the name changed, this"
        echo "           patch needs re-targeting to the new key, and issue 148w"
        echo "           needs updating with it."
        echo "           Rarer cause: the .dist template was replaced by a"
        echo "           hand-trimmed config. If so, does it drop other keys the"
        echo "           C-patches expect, and did those fail quietly?"
        return 1
    fi

    sed -i 's|^'"${KEY}"'[[:space:]]*=.*|'"${KEY}"' = '"${WANT}"'|' "${conf}"

    # Verify the write landed. A sed that matches but writes the wrong
    # thing is indistinguishable from success without reading it back,
    # and the whole point of this patch is that a wrong value here is
    # invisible until someone rolls a character and finds no spells.
    local now
    now="$(grep -m1 "^${KEY}[[:space:]]*=" "${conf}" | sed 's|.*=[[:space:]]*||' | tr -d '[:space:]')"
    if [[ "${now}" != "${WANT}" ]]; then
        echo "    [C022] ERROR: ${KEY} did not take the intended value"
        echo "           File: ${conf}"
        echo "           Wanted: ${WANT}"
        echo "           Reads back as: '${now}'"
        echo "           Completed before this: file present, key found,"
        echo "           substitution ran"
        echo "           To debug: is there more than one line defining this"
        echo "           key? The substitution rewrites every match, and a"
        echo "           later duplicate would win when the server parses the"
        echo "           file. Run: grep -n '^${KEY}' '${conf}'"
        return 1
    fi

    return 0
}
CONFIG_PROFILES[config_vanilla_custom_spells]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_custom_spells]="Enable custom starting spells (reads 148j pretrain table)"
# -- }}}
