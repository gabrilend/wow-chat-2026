#!/usr/bin/env bash
# C021 - SOAP Loopback Console (remote command channel for local scripts)
# Enable the worldserver's built-in SOAP endpoint, bound to loopback only,
# so project scripts (first user: scripts/bot-governor, issue 151) can send
# console commands to the RUNNING server — no restart, no attached terminal.
#
# Knobs written into worldserver.conf:
#   SOAP.Enabled = 1           listener spawns at worldserver boot
#   SOAP.IP      = "127.0.0.1" loopback only — never exposed off-machine
#   SOAP.Port    = 7878        upstream default, kept explicit here
#
# Security shape: SOAP authenticates with HTTP Basic against a real game
# account that must hold gmlevel >= 3 (SEC_ADMINISTRATOR). Enabling the
# listener alone grants nothing — `bot-governor setup` mints the dedicated
# governor account that scripts authenticate with. Loopback binding keeps
# the surface local to the host.
#
# Boot-time note: the worldserver reads SOAP.Enabled once at startup
# (Main.cpp spawns the listener thread conditionally), so the first
# activation needs one worldserver restart. After that the channel is
# always-on.
# Profiles: all

# -- {{{ config_soap_loopback_console
config_soap_loopback_console() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    # Anchor with [[:space:]]*= per the C020 lesson: a bare `.*=` after the
    # key name is greedy and can swallow longer keys sharing the prefix,
    # duplicating one line and deleting another.
    sed -i 's|^SOAP\.Enabled[[:space:]]*=.*|SOAP.Enabled = 1|'        "${conf}"
    sed -i 's|^SOAP\.IP[[:space:]]*=.*|SOAP.IP = "127.0.0.1"|'        "${conf}"
    sed -i 's|^SOAP\.Port[[:space:]]*=.*|SOAP.Port = 7878|'           "${conf}"
}
CONFIG_PROFILES[config_soap_loopback_console]="all"
CONFIG_DESCRIPTIONS[config_soap_loopback_console]="SOAP console on loopback 127.0.0.1:7878"
# -- }}}
