# 128 - Script Command History

## Status
- Created: 2026-04-14
- Phase: 3
- Priority: Low

## Problem

No visibility into which build scripts were run recently. When debugging build issues or
trying to remember what actions were taken, there's no record of script invocations.

## Intended Behavior

A `.history` file tracks the last 10 commands run across all build scripts.

### Storage Locations

- **Volatile:** `/tmp/wow-chat-2/.history` - Updated on every script run
- **Persistent:** `${DIR}/.history` - Saved on expensive operations only

### History Format

```
2026-04-14 17:23:45 compile --profile beta
2026-04-14 17:20:12 update
2026-04-14 17:15:33 redownload-source --dry-run
2026-04-14 16:45:00 validate
...
```

Newest at top, oldest at bottom. Maximum 10 entries.

### Cycle Algorithm

When adding a new entry:
1. Read existing history (up to 9 lines)
2. Prepend new entry with timestamp
3. Write back (newest first, oldest truncated if > 10)

```bash
# Pseudocode
new_entry="$(date '+%Y-%m-%d %H:%M:%S') ${SCRIPT_NAME} ${ARGS}"
existing=$(head -9 "${HISTORY_FILE}")
echo -e "${new_entry}\n${existing}" > "${HISTORY_FILE}"
```

### Persistence Triggers

Save volatile history to disk on expensive operations:
- `compile` - After successful build
- `redownload-source` - After removing source
- `install` - After full installation
- `promote` - After promoting shadow to main

### Implementation

Each script sources a shared history function:

```bash
# At top of script, after DIR definition
HISTORY_TMP="/tmp/wow-chat-2/.history"
HISTORY_DISK="${DIR}/.history"

# {{{ record_history
record_history() {
    local cmd="$1"
    local tmp_dir="/tmp/wow-chat-2"
    mkdir -p "${tmp_dir}"

    local entry="$(date '+%Y-%m-%d %H:%M:%S') ${cmd}"
    local existing=""

    if [[ -f "${HISTORY_TMP}" ]]; then
        existing=$(head -9 "${HISTORY_TMP}")
    fi

    if [[ -n "${existing}" ]]; then
        echo -e "${entry}\n${existing}" > "${HISTORY_TMP}"
    else
        echo "${entry}" > "${HISTORY_TMP}"
    fi
}
# }}}

# {{{ persist_history
persist_history() {
    if [[ -f "${HISTORY_TMP}" ]]; then
        cp "${HISTORY_TMP}" "${HISTORY_DISK}"
    fi
}
# }}}
```

### Script Integration

Each script records at start, persists at end (if expensive):

```bash
# At script start
record_history "compile ${*}"

# ... do work ...

# At script end (expensive operations only)
persist_history
```

### Viewing History

```bash
cat /tmp/wow-chat-2/.history    # Recent (volatile)
cat .history                     # Persisted snapshot
```

Or add a `scripts/history` command:
```bash
#!/bin/bash
# scripts/history - Show recent script commands
cat /tmp/wow-chat-2/.history 2>/dev/null || cat "${DIR}/.history" 2>/dev/null || echo "No history"
```

## Implementation Steps

1. Create history helper functions (inline in each script, no shared file)
2. Add `record_history` call at start of each script
3. Add `persist_history` call at end of expensive scripts
4. Create `scripts/history` viewer script
5. Test history cycling (run > 10 commands, verify oldest drops)
6. Test persistence (run compile, check .history in project root)

## Scripts to Modify

Record history (all scripts):
- compile, update, install, redownload-source
- validate, promote
- apply-patches, boost
- switch, worldserver, authserver

Persist history (expensive operations):
- compile (after successful build)
- install (after full installation)
- redownload-source (after removing source)
- promote (after promotion)

## Edge Cases

### Race Conditions
Multiple scripts running simultaneously could corrupt history.
Accept this limitation - history is informational, not critical.

### Missing /tmp/
If `/tmp/wow-chat-2/` doesn't exist, create it. Scripts already use this directory.

### Restore from Disk
On fresh boot, `/tmp/` is empty. Could optionally restore from disk:
```bash
if [[ ! -f "${HISTORY_TMP}" && -f "${HISTORY_DISK}" ]]; then
    cp "${HISTORY_DISK}" "${HISTORY_TMP}"
fi
```

## Related Files

- All scripts in `scripts/` directory
- `/tmp/wow-chat-2/` - Temporary directory for build artifacts
- `.history` - Persisted history in project root
