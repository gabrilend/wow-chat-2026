# 346 - Authserver Public IP Detection

## Status: Open

## Current Behavior

The `scripts/update-realmlist-ip` script runs every time authserver starts:

1. Queries 4 external services (ifconfig.me, icanhazip.com, api.ipify.org, checkip.amazonaws.com)
2. Requires consensus from at least 2 services
3. Updates `acore_auth.realmlist` table with detected IP
4. Takes 5-20 seconds depending on network latency

This runs on every authserver start, even if:
- The IP hasn't changed
- The server was restarted moments ago
- Multiple restarts happen in quick succession during development

No warning is issued when IP changes - the database is silently updated.

## Intended Behavior

### Daily Caching

Only perform the external IP lookup once per day:

1. Store last detected IP and timestamp in a cache file (e.g., `tmp/public-ip-cache`)
2. On authserver start, check cache age
3. If cache is < 24 hours old, use cached value
4. If cache is stale or missing, perform fresh lookup
5. Compare new IP to cached IP before updating database

### IP Change Warning

When the public IP changes:

1. Display prominent warning to console
2. Show old IP vs new IP
3. Remind user to update DNS record if using domain name
4. Log the change with timestamp

Example output:
```
=== PUBLIC IP CHANGED ===
  Previous: 203.0.113.45
  Current:  198.51.100.72

  If using a domain name, update your DNS A record.
  Realmlist database has been updated automatically.
=============================
```

### Cache File Format

Simple text file at `${DIR}/tmp/public-ip-cache`:
```
IP=198.51.100.72
TIMESTAMP=1712678400
```

## Suggested Implementation Steps

1. Add cache file path constant to `update-realmlist-ip`
2. Add `read_cache()` function - returns IP and timestamp or empty
3. Add `write_cache()` function - stores current IP and Unix timestamp
4. Add `is_cache_fresh()` function - checks if timestamp < 24 hours old
5. Modify `main()` to check cache before querying external services
6. Add IP comparison and warning message when change detected
7. Update `scripts/azerothcore` comment to note caching behavior

## Related Files

- `scripts/update-realmlist-ip` - Current implementation
- `scripts/azerothcore:364-371` - Where the script is called (authserver command)
- `scripts/credentials` - Sourced for MySQL access

## Notes

The current implementation was created without an issue file. This issue retroactively
documents the feature and adds the caching requirement.

Why daily: ISPs with dynamic IP typically don't change more than once per day. Checking
more frequently wastes bandwidth and adds startup latency. Checking less frequently
risks stale realmlist entries preventing player connections.

Why warn on change: DNS records have TTL. If using a domain name, the user needs to
know their IP changed so they can update the A record. The realmlist database update
is automatic, but DNS is external to this system.
