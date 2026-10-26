#!/usr/bin/env bash

E_PATCHES_DIR="${BASH_SOURCE[0]%/*}"
source "${E_PATCHES_DIR}/E-helpers.sh" || { echo "ERROR: patches/E-helpers.sh did not load"; return 1 2>/dev/null || exit 1; }
for e_patch_file in "${E_PATCHES_DIR}"/E[0-9][0-9][0-9]-*.sh "${E_PATCHES_DIR}"/E[0-9][0-9][0-9]-*/E[0-9][0-9][0-9]-*.sh; do
    [[ -f "${e_patch_file}" ]] || continue                  # a pattern that matched nothing
    source "${e_patch_file}" || { echo "ERROR: ${e_patch_file} did not load"; return 1 2>/dev/null || exit 1; }
done
unset e_patch_file
