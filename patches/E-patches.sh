#!/usr/bin/env bash
# E-patches.sh - loads the install steps, one file each (issue 150)
#
# For a general audience: the install steps (PHASE_END patches: SQL, links and
# config files set up after the server is built) are one file each,
# patches/E0NN-<name>.sh, with what they share in patches/E-helpers.sh. This
# loads the helpers and then every step file, so whatever loads this file
# (patches/patches.sh, the tests) gets every step as before. Which steps a
# profile runs, and in what order, is its list in patches/patches.sh.
# A step that fails to load stops the loading with its name.

E_PATCHES_DIR="${BASH_SOURCE[0]%/*}"
source "${E_PATCHES_DIR}/E-helpers.sh" || { echo "ERROR: patches/E-helpers.sh did not load"; return 1 2>/dev/null || exit 1; }
for e_patch_file in "${E_PATCHES_DIR}"/E[0-9][0-9][0-9]-*.sh; do
    source "${e_patch_file}" || { echo "ERROR: ${e_patch_file} did not load"; return 1 2>/dev/null || exit 1; }
done
unset e_patch_file
