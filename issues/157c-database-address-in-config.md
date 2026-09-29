# 157c - Database Address in Config

## Status
- Created: 2026-09-23
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocked by:** 157a
- **Blocks:** 157d, 157e, 157f

## Overview

Every place that connects to MySQL assumes it's on the same machine. This
issue makes all of them read the database machine's address from the roles
file.

## Current Behavior

- `config/patches/C001-database-connections.sh` writes 127.0.0.1 into
  authserver.conf, worldserver.conf and the playerbots config.
- Helper scripts connect through the local client on the default host:
  `scripts/update-realmlist-ip`, `scripts/set-active-realm`,
  `scripts/mysql-client`, `scripts/validate*`.

## Intended Behavior

- C001 takes the host from the roles file's `database` entry. With that
  role set to `local`, it writes 127.0.0.1 exactly as today, so nothing
  changes until the roles file does.
- Every helper script passes the same host to the MySQL client.
- A missing roles file is an error that names the file, not a silent
  fallback to 127.0.0.1.

## Implementation Steps

1. Grep the whole project for `127.0.0.1`, `localhost` and `3307`, and list
   each hit with the role it belongs to.
2. Change C001, then each script, to read the roles file.
3. Extend `scripts/test-profile-config-gates` so it checks the generated
   connection strings against the roles file.

## Open Questions

None yet.

## Related
- `config/patches/C001-database-connections.sh`
- `issues/157a-role-hosts-file.md`
