#!/usr/bin/env bash

patch_E064_beta_two_side_who()   { _beta_two_side_step E064 03-two-side-who apply; }
unpatch_E064_beta_two_side_who() { _beta_two_side_step E064 03-two-side-who revert; }
