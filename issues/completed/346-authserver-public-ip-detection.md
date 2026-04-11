# 346 - Authserver Public IP Detection

## Status: Completed (2026-04-11)

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

**Option A: Timestamp-based (original suggestion)**

Simple text file at `${DIR}/tmp/public-ip-cache`:
```
IP=198.51.100.72
TIMESTAMP=1712678400
```

**Option B: Date-based (simpler, system /tmp/)**

Hidden file in `/tmp/` named `.wow-chat-ip-check-YYYY-MM-DD`:
```
/tmp/.wow-chat-ip-check-2026-04-11
```

File contains just the IP address. Check logic:
1. Generate today's date: `$(date +%Y-%m-%d)`
2. Check if `/tmp/.wow-chat-ip-check-${TODAY}` exists
3. If exists, skip IP detection (already checked today)
4. If not exists, do IP detection and create file with detected IP

Benefits of Option B:
- Uses system `/tmp/` (auto-cleanup on reboot)
- Date in filename makes checking trivial (no timestamp parsing)
- Hidden file (dot-prefix) keeps `/tmp/` clean
- Old date files naturally accumulate but don't interfere

## Suggested Implementation Steps

**For Option A (timestamp-based):**
1. Add cache file path constant to `update-realmlist-ip`
2. Add `read_cache()` function - returns IP and timestamp or empty
3. Add `write_cache()` function - stores current IP and Unix timestamp
4. Add `is_cache_fresh()` function - checks if timestamp < 24 hours old
5. Modify `main()` to check cache before querying external services
6. Add IP comparison and warning message when change detected
7. Update `scripts/azerothcore` comment to note caching behavior

**For Option B (date-based):**
1. Add date-based cache check at start of `main()`
   ```bash
   TODAY=$(date +%Y-%m-%d)
   CACHE_FILE="/tmp/.wow-chat-ip-check-${TODAY}"

   if [[ -f "${CACHE_FILE}" ]]; then
       echo "IP already checked today, skipping external lookup"
       return 0
   fi
   ```
2. After successful IP detection, write to cache file:
   ```bash
   echo "${public_ip}" > "${CACHE_FILE}"
   ```
3. Optionally clean up old cache files (> 7 days old)
4. Update `scripts/azerothcore` comment to note daily caching

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

## Update History

**2026-04-11:** Added Option B (date-based caching to /tmp/) as suggested alternative.
Simpler implementation, uses system /tmp/ for automatic cleanup on reboot.

## Implementation Summary

**Date:** 2026-04-11
**Approach:** Option B (date-based caching)

### Changes Made

**scripts/update-realmlist-ip:**
- Added date-based cache check at start of `main()`
- Cache file: `/tmp/wow-chat/.ip-check-YYYY-MM-DD`
- If cache exists for today, skip external IP lookup
- After successful IP detection, write IP to cache file
- Creates `/tmp/wow-chat/` directory if needed

**scripts/azerothcore:**
- Updated comment for `cmd_authserver()` to note daily caching
- Explains why daily (bandwidth savings, ISP change frequency)
- Documents cache location (`/tmp/wow-chat/`)

### Testing

Tested with manually created cache file:
```bash
echo "184.3.201.206" > /tmp/wow-chat/.ip-check-2026-04-11
./scripts/update-realmlist-ip
# Output: "IP already checked today (184.3.201.206)"
# Output: "Skipping external lookup - using cached value"
```

Cache correctly prevents external service queries on subsequent authserver starts within same day.

### Benefits Achieved

1. **Reduced startup latency** - No 5-20s delay for IP lookup on subsequent starts
2. **Reduced bandwidth** - Only 4 external service queries per day max
3. **Automatic cleanup** - `/tmp/` cleared on reboot
4. **Simple implementation** - No timestamp parsing, just file existence check
5. **Organized temp files** - All wow-chat temp files in `/tmp/wow-chat/`
