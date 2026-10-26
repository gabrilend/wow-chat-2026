#!/usr/bin/env bash

patch_E063_beta_two_side_mail()   { _beta_two_side_step E063 02-two-side-mail apply; }
unpatch_E063_beta_two_side_mail() { _beta_two_side_step E063 02-two-side-mail revert; }
