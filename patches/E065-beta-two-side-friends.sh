#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E065
# profiles:   beta
# priority:   2950
# kind:       sql
# about:      Beta: friends of the other faction (permission 29), every account, beta's realm.
# ==== end of header ====
# E065-beta-two-side-friends.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E065_beta_two_side_friends
# Beta: friends of the other faction (permission 29), every account, beta's realm.
patch_E065_beta_two_side_friends()   { _beta_two_side_step E065 04-two-side-friends apply; }
unpatch_E065_beta_two_side_friends() { _beta_two_side_step E065 04-two-side-friends revert; }
# -- }}}
# ==== footer of E065 ====
# lines:      21
# ==== end of footer ====
