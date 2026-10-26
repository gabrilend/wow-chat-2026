#!/usr/bin/env bash

config_soap_loopback_console() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^SOAP\.Enabled[[:space:]]*=.*|SOAP.Enabled = 1|'        "${conf}"
    sed -i 's|^SOAP\.IP[[:space:]]*=.*|SOAP.IP = "127.0.0.1"|'        "${conf}"
    sed -i 's|^SOAP\.Port[[:space:]]*=.*|SOAP.Port = 7878|'           "${conf}"
}
CONFIG_DESCRIPTIONS[config_soap_loopback_console]="SOAP console on loopback 127.0.0.1:7878"
