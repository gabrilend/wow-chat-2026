#!/usr/bin/env bash
# E062-beta-two-side-trade.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E062_beta_two_side_trade
# Beta: trade with the other faction (permission 51), every account, beta's realm.
patch_E062_beta_two_side_trade()   { _beta_two_side_step E062 01-two-side-trade apply; }
unpatch_E062_beta_two_side_trade() { _beta_two_side_step E062 01-two-side-trade revert; }
# -- }}}
