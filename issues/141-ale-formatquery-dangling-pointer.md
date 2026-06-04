# 141 - ALE FormatQuery Dangling Pointer (B023)

## Status
- Created: 2026-05-20
- Phase: 1 (Foundation)
- Priority: High (corrupts query results for any Lua caller using parameterized sync queries)
- Patch: B023

## Current Behavior

When a Lua script calls one of ALE's sync DB query methods with format
args after the query string — e.g.:

```lua
local q = WorldDBQuery("SELECT * FROM creature_template WHERE entry = ?", 12345)
```

…the server may return wrong results, return no results when results
exist, or crash. The bug is intermittent and depends on what happens
to occupy the freed memory between the dangling-pointer creation and
the read.

## Root Cause

In `modules/mod-ale/src/LuaEngine/methods/GlobalMethods.h`, six sync
DB query methods (`WorldDBQuery`, `WorldDBExecute`, `CharDBQuery`,
`CharDBExecute`, `AuthDBQuery`, `AuthDBExecute`) share this exact
shape:

```cpp
const char* query = ALE::CHECKVAL<const char*>(L, 1);

int numArgs = lua_gettop(L);
if (numArgs > 1)
    query = ALE::FormatQuery(L, query).c_str();   // ⚠️ dangling pointer

ALEQuery result = WorldDatabase.Query(query);     // reads freed memory
```

`ALE::FormatQuery(L, query)` returns `std::string` by value. `.c_str()`
returns a pointer into that temporary `std::string`'s internal buffer.
The temporary's lifetime ends at the closing `;` of the `if`
statement. The next line then passes a pointer to freed memory to the
database driver. Classic dangling-pointer bug.

The bug only triggers when **numArgs > 1** — i.e., when format args are
passed. Bare single-string queries skip the `FormatQuery` branch
entirely and work fine.

## Discovery Path

Found 2026-05-20 while diagnosing why `src/lua/ambush.lua.disabled`
existed and what its replacement preserved or lost. The disabled file
carried a comment:

> Loads all creature data into memory at startup to avoid runtime SQL
> queries which have a buffer corruption bug in ALE's WorldDBQuery
> implementation.

Reading `GlobalMethods.h` against that hint revealed the
`FormatQuery().c_str()` pattern. The replacement `ambush.lua`
sidestepped the bug by switching to `WorldDBQueryAsync` — the async
path doesn't call `FormatQuery` at all, so it's structurally immune.

## Affected Versions

`git log -S "FormatQuery(L, query).c_str()"` shows the bug was
introduced in upstream commit `a5b2182` ("feat: add support for
parameterized SQL queries with argument escaping #221") and has never
been touched since. Every ALE/Eluna version that supports parameterized
queries has this bug.

## Intended Behavior

The `std::string` returned by `FormatQuery` must live until at least
the `Database.Query()` call returns. Standard fix: bind the temporary
to a named variable whose scope extends past the query call.

```cpp
const char* query = ALE::CHECKVAL<const char*>(L, 1);

int numArgs = lua_gettop(L);
std::string formattedQuery;
if (numArgs > 1)
{
    formattedQuery = ALE::FormatQuery(L, query);
    query = formattedQuery.c_str();
}

ALEQuery result = WorldDatabase.Query(query);
```

Now `formattedQuery` lives until the end of the enclosing function
scope, which definitely outlasts `WorldDatabase.Query()`.

## Implementation

`patches/B023-ale-formatquery-lifetime.sh` applies the fix at all six
call sites with a single anchored `sed -z` substitution. The
replacement is wrapped in marker comments
(`// {{{ B023-formatquery-lifetime ... // }}} B023-formatquery-lifetime`)
so the unpatch can locate the exact insertion to reverse — round-trip
is byte-identical against upstream HEAD.

Registered in `patches/patches.sh` for the `release` and `beta`
profiles. Witness function `patch_needs_applying_B023` greps for the
marker string; if present, the patch is already applied.

## Verification

After applying B023 and rebuilding:

```lua
-- This should work reliably, not crash or corrupt:
local q = WorldDBQuery("SELECT entry, name FROM creature_template WHERE entry = ?", 12345)
if q then
    print(q:GetUInt32(0), q:GetString(1))
end
```

Pre-B023: result may be empty, wrong, or crash.
Post-B023: returns correct row.

## Upstream

This bug exists in every ALE/Eluna fork that has parameterized query
support. The fix is worth submitting upstream — see
`docs/patches/contributing-upstream.md` for the workflow. Target repo:
`azerothcore/mod-eluna` (upstream still uses the Eluna name; strip the
ALE rename when porting).

When upstream merges, B023 retires:
1. Remove `B023` from `PHASE_BEGIN_PATCHES` in `patches.sh`
2. Move `patches/B023-ale-formatquery-lifetime.sh` to `patches/retired/`
3. Mark this issue Closed with the upstream commit SHA
4. Update `issues/126` inventory table

## Follow-up

Once B023 is committed and verified in-game, `src/lua/ambush.lua.disabled`
becomes safe to retire. Its only justification was the FormatQuery bug;
once the bug is fixed, the disabled file is pure code drift. Track in a
follow-up issue or as a final step of this one.

## Related

- `docs/patches/contributing-upstream.md` — how to submit upstream
- `issues/126-upstream-warning-fixes.md` — patch inventory + lifecycle rules
- `issues/210-ambush-per-player-queue.md` — the ambush refactor unblocked
  by switching to async (which sidestepped this bug)
- `src/lua/ambush.lua.disabled` — historical cache workaround
