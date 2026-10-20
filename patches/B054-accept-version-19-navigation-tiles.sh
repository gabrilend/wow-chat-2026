#!/usr/bin/env bash

B054_EDITS=$(printf '%s\t%s\t%s\n' \
    'src/common/Collision/Management/MMapMgr.cpp' \
    '        if (fileHeader.mmapVersion != MMAP_VERSION)' \
    '        if (fileHeader.mmapVersion != MMAP_VERSION && fileHeader.mmapVersion != 19)')

patch_B054_accept_version_19_navigation_tiles() {
    line_edits_apply B054 <<< "${B054_EDITS}"
}

unpatch_B054_accept_version_19_navigation_tiles() {
    line_edits_revert B054 <<< "${B054_EDITS}"
}
