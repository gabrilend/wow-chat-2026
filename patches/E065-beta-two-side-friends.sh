#!/usr/bin/env bash

patch_E065_beta_two_side_friends()   { _beta_two_side_step E065 04-two-side-friends apply; }
unpatch_E065_beta_two_side_friends() { _beta_two_side_step E065 04-two-side-friends revert; }
