# 157e - Auth Machine and Router

## Status
- Created: 2026-09-23
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocked by:** 157b, 157c

## Overview

The authserver runs on its own machine. It hands out the world machine's
address in the realm list, so the router has to send two ports to two
different machines.

## Current Behavior

- The authserver and the worldserver run on the same machine, and the realm
  list's address is that machine's public address
  (`scripts/update-realmlist-ip`, cached daily by issue 113).
- The router forwards the auth port and the world port to that one machine.

## Intended Behavior

- The router forwards 4362 to the auth machine and 4462 to the world
  machine. Both machines are on fixed LAN addresses.
- The realm list's public address is still the house's public IP, since
  outside players reach the world machine through the router's forward.
- The realm list's local address fields hold the world machine's LAN
  address, so players inside the house connect directly.
- `update-realmlist-ip` runs on the auth machine.

## Implementation Steps

1. Record the router's forwarding rules (by hand, since the router is not
   scriptable) in `docs/deployment.md`.
2. Change `update-realmlist-ip` to write the local address fields from the
   roles file.
3. Ship and start the authserver with `scripts/deploy`, then log in from
   inside and outside the house.

## Open Questions

1. Which router is it? Can it reserve LAN addresses by MAC address?

## Related
- `scripts/update-realmlist-ip`
- `config/patches/C010-network-ports.sh`, `C011-realmlist-setup.sh`
- `docs/connection-guide.md`
