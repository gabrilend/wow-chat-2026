# 157d - Database Machine

## Status
- Created: 2026-09-23
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocked by:** 157b, 157c

## Overview

MySQL moves to its own mini-computer. This is the only step that touches
player data, so it moves a copy first, checks it, and switches over only
after the copy matches.

## Current Behavior

- The project's own MySQL build (`mysql/`, issue 105) runs on the
  development machine and listens on 127.0.0.1:3307.
- The database password has been public since January (see the recent
  commit about it). That mattered little while MySQL listened only on its
  own machine; it matters once MySQL listens on the network.

## Intended Behavior

- MySQL runs on the database machine and listens on its LAN address,
  port 3307.
- Accounts are allowed in only from the auth and world machines' addresses
  (and the development machine's, for tools). The router never forwards
  3307.
- The database password is changed before MySQL starts listening on the
  LAN, and kept out of git (issue 107).
- Moving the data is a tool: dump every project database, restore on the
  new machine, and compare row counts table by table before switching.

## Implementation Steps

1. Install MySQL on the database machine: copy the build, or build it
   through issue 154.
2. Change the password, and set up grants per address.
3. A dump / restore / compare tool, run with both servers stopped.
4. Change the roles file's `database` entry, regenerate the configs (157c),
   and check with `scripts/deploy status`.

## Open Questions

1. Should the development machine keep its own copy of the databases for
   testing, or always use the database machine's?
2. Backups: how often, and kept on which machine?

## Related
- `issues/completed/105-project-local-database`
- `issues/107-credential-manager-script`
- `mysql/conf/my.cnf`
