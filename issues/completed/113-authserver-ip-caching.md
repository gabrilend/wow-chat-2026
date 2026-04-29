# 113 - Authserver Public IP Caching

**Phase:** 1 (Foundation & Tooling)
**Effect:** Authserver starts faster by caching daily IP lookups
**Status:** Completed (2026-04-11)

---

## The Effect

Starting the authserver now skips external IP detection if already checked today. The 5-20 second delay from querying external services only happens once per day instead of every startup.

When IP does change, a warning is displayed and the realmlist database is updated automatically.

---

## What This Solved

### Before (Every Startup)

**The slowdown:**
```bash
$ ./scripts/azerothcore authserver

Detecting public IP address...
  Querying ifconfig.me...
  Querying icanhazip.com...
  Querying api.ipify.org...
  Querying checkip.amazonaws.com...
  Consensus: 198.51.100.72
Updating realmlist...

# 5-20 seconds every time
```

**Why it happened:**

The `update-realmlist-ip` script ran unconditionally on every authserver start:
1. Query 4 external services
2. Require consensus from at least 2
3. Update `acore_auth.realmlist` table
4. Only then proceed to start authserver

**Problems:**
- 5-20 second delay depending on network latency
- Unnecessary during rapid development restarts
- Bandwidth waste (4 HTTP requests)
- No warning when IP actually changes

**During development:**
```bash
# Typical debug session
./scripts/azerothcore authserver  # 15 second wait
# test something, find bug
./scripts/azerothcore authserver  # 15 second wait
# fix bug
./scripts/azerothcore authserver  # 15 second wait
# verify fix
./scripts/azerothcore authserver  # 15 second wait

# 60 seconds wasted on IP detection
```

### After (Daily Caching)

**Fast restarts:**
```bash
$ ./scripts/azerothcore authserver

IP already checked today (198.51.100.72)
Skipping external lookup - using cached value

Starting Auth server...
```

**First start of the day:**
```bash
$ ./scripts/azerothcore authserver

Detecting public IP address...
  Querying external services...
  Consensus: 198.51.100.72
IP cached for today.

Starting Auth server...
```

**When IP changes:**
```
=== PUBLIC IP CHANGED ===
  Previous: 203.0.113.45
  Current:  198.51.100.72

  If using a domain name, update your DNS A record.
  Realmlist database has been updated automatically.
=============================
```

---

## Implementation

### Date-Based Cache Files

Cache stored in `/tmp/wow-chat/` with today's date in filename:

```bash
/tmp/wow-chat/.ip-check-2026-04-11
```

File contains just the IP address:
```
198.51.100.72
```

### Detection Logic

```bash
# At start of update-realmlist-ip main():

TODAY=$(date +%Y-%m-%d)
CACHE_FILE="/tmp/wow-chat/.ip-check-${TODAY}"

if [[ -f "${CACHE_FILE}" ]]; then
    CACHED_IP=$(cat "${CACHE_FILE}")
    echo "IP already checked today (${CACHED_IP})"
    echo "Skipping external lookup - using cached value"
    return 0
fi
```

### Cache Creation

```bash
# After successful IP detection:

mkdir -p /tmp/wow-chat
echo "${public_ip}" > "${CACHE_FILE}"
```

### Why Date in Filename

**Option A (rejected):** Timestamp in file content
- Requires parsing
- Timezone edge cases
- More complex "is it fresh?" logic

**Option B (chosen):** Date in filename
- File exists = already checked today
- No parsing needed
- Auto-cleanup: reboot clears `/tmp/`
- Old files don't interfere

---

## Why This Matters

**Development Velocity**

During active development, authserver restarts happen frequently:
- Testing Lua script changes (ALE hot-reload)
- Debugging connection issues
- Verifying bot behavior

Each restart was 5-20 seconds slower than necessary. Over a session, this adds up to minutes of waiting.

**ISP Change Frequency**

Dynamic IPs from residential ISPs typically change:
- Once per day at most
- Often only on router reboot
- Sometimes weekly/monthly

Checking every startup is paranoid. Checking daily is sufficient.

**DNS TTL Awareness**

When IP changes, users with domain names need to update their DNS A record. The warning message reminds them - the realmlist database update is automatic, but external DNS is manual.

---

## Related Phase 1 Issues

- 105 - project-local-database (MySQL where realmlist lives)
- 101 - verify-server-startup (server startup flow)

---

## Lessons Learned

### Cache Location Matters

Using `/tmp/wow-chat/` instead of project directory:
- Auto-cleanup on reboot (fresh check on new boot)
- No git tracking needed
- System-managed lifecycle

Project-local cache would need manual cleanup and .gitignore entries.

**Lesson:** Use system temp directories for ephemeral state.

### Date as State

The filename `/.ip-check-2026-04-11` encodes both:
- **What** was checked (IP)
- **When** it was checked (today's date)

No need for timestamps, parsing, or staleness calculation. File exists for today = done.

**Lesson:** Encode state in filesystem structure when possible.

### Warn on Change, Not on Check

The original script silently updated the database. Users didn't know their IP changed. Now:
- Change detected → prominent warning
- DNS reminder included
- Old vs new IP displayed

**Lesson:** Silent updates hide important information.

---

## Testing

```bash
# Create cache manually to test skip behavior
echo "184.3.201.206" > /tmp/wow-chat/.ip-check-$(date +%Y-%m-%d)

$ ./scripts/update-realmlist-ip
IP already checked today (184.3.201.206)
Skipping external lookup - using cached value

# Delete cache to force fresh lookup
rm /tmp/wow-chat/.ip-check-*

$ ./scripts/update-realmlist-ip
Detecting public IP address...
# ... external queries ...
```

---

## Files Modified

- `scripts/update-realmlist-ip` - Added cache check and creation
- `scripts/azerothcore` - Updated comments in `cmd_authserver()`

---

## Phase 1 Contribution

This issue enables **Phase 1: Foundation & Tooling** by ensuring:
> "Development iteration is fast"

Developer time is precious. Waiting 15 seconds every server restart is death by a thousand cuts. Caching the IP lookup removes friction from the most common development loop: change code, restart server, test.

The server should start as fast as possible. Network calls on startup are a code smell unless absolutely necessary. Once per day is necessary; once per restart is not.
