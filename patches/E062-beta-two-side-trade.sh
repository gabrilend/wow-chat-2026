#!/usr/bin/env bash

patch_E062_beta_two_side_trade()   { _beta_two_side_step E062 01-two-side-trade apply; }
unpatch_E062_beta_two_side_trade() { _beta_two_side_step E062 01-two-side-trade revert; }
