#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E064
# profiles:   beta
# priority:   1940
# kind:       install
# about:      Beta: the other faction in the /who list (permission 28), every account, beta's realm.
# ==== end of header ====
# E064-beta-two-side-who.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E064_beta_two_side_who
# Beta: the other faction in the /who list (permission 28), every account, beta's realm.
patch_E064_beta_two_side_who()   { _beta_two_side_step E064 03-two-side-who apply; }
unpatch_E064_beta_two_side_who() { _beta_two_side_step E064 03-two-side-who revert; }
# -- }}}
# ==== footer of E064 ====
# lines:      21
# ==== end of footer ====
