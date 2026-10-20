#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E063
# profiles:   beta
# priority:   1930
# kind:       install
# about:      Beta: mail to the other faction (permission 27), every account, beta's realm.
# ==== end of header ====
# E063-beta-two-side-mail.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E063_beta_two_side_mail
# Beta: mail to the other faction (permission 27), every account, beta's realm.
patch_E063_beta_two_side_mail()   { _beta_two_side_step E063 02-two-side-mail apply; }
unpatch_E063_beta_two_side_mail() { _beta_two_side_step E063 02-two-side-mail revert; }
# -- }}}
# ==== footer of E063 ====
# lines:      21
# ==== end of footer ====
