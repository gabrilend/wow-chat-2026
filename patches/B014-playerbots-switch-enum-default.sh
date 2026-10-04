#!/usr/bin/env bash
# B014-playerbots-switch-enum-default.sh
# Fixes switch enum warnings by adding default case
#
# Warning: case value not in enumerated type 'WSBotStrategy' [-Wswitch]
#
# The WSBotStrategy enum only has values 0-3, but the switch uses cases 0-9.
# This appears to be dead code or enum mismatch. Adding default: silences
# the warning without changing runtime behavior (unreachable cases remain so).
#
# Affected: BattleGroundTactics.cpp:2188-2195

# {{{ patch_B014_playerbots_switch_enum_default
#
# Rewritten 2026-10-03 as exact whole-line edits (patches.sh,
# line_edits_apply / line_edits_revert): each edited line carries the tag
# "  // B014", the revert turns back only tagged lines, and an old line not
# found the expected number of times stops the patch as stale. The old sed
# revert also changed lines upstream had since written the fixed way
# (scripts/verify-patches). Kept: the switch-on-enum casts. Dropped: the inserted "default: break;",
# made unnecessary by the cast on that same switch.

# path (from the source root) <TAB> old line <TAB> new line
B014_EDITS=$(cat <<'EDITS'
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	        switch (bgType)	        switch (static_cast<int>(bgType))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	    switch (bgType)	    switch (static_cast<int>(bgType))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	        switch (bot->GetMotionMaster()->GetCurrentMovementGeneratorType())	        switch (static_cast<int>(bot->GetMotionMaster()->GetCurrentMovementGeneratorType()))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	    switch (bgType)	    switch (static_cast<int>(bgType))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	            switch (strategy)	            switch (static_cast<int>(strategy))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	            switch (strategy)	            switch (static_cast<int>(strategy))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	                switch (strategy)	                switch (static_cast<int>(strategy))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	    switch (bgType)	    switch (static_cast<int>(bgType))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	        switch (bgType)	        switch (static_cast<int>(bgType))
modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp	    switch (bg->GetBgTypeID())	    switch (static_cast<int>(bg->GetBgTypeID()))
EDITS
)

# {{{ patch_B014_playerbots_switch_enum_default
patch_B014_playerbots_switch_enum_default() {
    line_edits_apply B014 <<< "${B014_EDITS}"
}
# }}}

# {{{ unpatch_B014_playerbots_switch_enum_default
unpatch_B014_playerbots_switch_enum_default() {
    line_edits_revert B014 <<< "${B014_EDITS}"
}
# }}}
