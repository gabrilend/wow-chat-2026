#!/usr/bin/env bash
# B054 - The server accepts navigation tiles built by version 19 of the
# tile generator as well as version 20
# 2026-10-15 (found reading the world server's log for Felicity's group).
#
# For a general audience: the server finds walking paths on a "navigation
# mesh", a map of walkable ground cut into tiles (data-files/mmaps, 3,780
# files) made once by a separate program, the tile generator. Each tile
# records which version of the generator made it, and the server refuses
# tiles of any other version. Upstream raised that number from 19 to 20 on
# 2026-07-19 (a fix for falling off the edges of Blade's Edge Arena), to
# make everyone rebuild their tiles; the tile file's layout did not change.
# This project's tiles were built on 2026-04-02, at version 19, so every
# build since the 2026-08-22 merge refused all of them: creatures, bots and
# buddies have walked without a mesh since (the log: "was built with
# generator v19, expected v20"). Rebuilding the tiles (scripts/extract-maps
# --mmaps) takes two to three hours of the machine's full effort; this
# lets the old tiles load meanwhile. What the old tiles lack is only July's
# two improvements: the arena's edges, and the steep-slope marking the bot
# module's walking avoids. Once the tiles are rebuilt at 20, the patch can
# be dropped from the list.
#
# Where: MMapMgr.cpp's tile loader, the one line comparing the tile's
# version with MMAP_VERSION.
#
# Mechanics: one exact whole-line edit (patches.sh, line_edits_apply /
# line_edits_revert), tagged "  // B054"; the revert turns back only the
# tagged line; an old line not found exactly once stops the patch as stale.
# Parallelizable: Yes

# path (from the source root) <TAB> old line <TAB> new line
B054_EDITS=$(printf '%s\t%s\t%s\n' \
    'src/common/Collision/Management/MMapMgr.cpp' \
    '        if (fileHeader.mmapVersion != MMAP_VERSION)' \
    '        if (fileHeader.mmapVersion != MMAP_VERSION && fileHeader.mmapVersion != 19)')

# {{{ patch_B054_accept_version_19_navigation_tiles
patch_B054_accept_version_19_navigation_tiles() {
    line_edits_apply B054 <<< "${B054_EDITS}"
}
# }}}

# {{{ unpatch_B054_accept_version_19_navigation_tiles
unpatch_B054_accept_version_19_navigation_tiles() {
    line_edits_revert B054 <<< "${B054_EDITS}"
}
# }}}
