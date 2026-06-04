# 137 - Shadow Conf Path Baked Into Binary

## Status
- Created: 2026-04-28
- Phase: 1 (Foundation)
- Priority: High (causes promoted binaries to read wrong config)

## Current Behavior

The compile step uses `installed-files-shadow` as `CMAKE_INSTALL_PREFIX`.
AzerothCore's CMake bakes that path into the binary as the default
configuration directory. After `promote` copies the binary to
`installed-files-${PROFILE}/bin/`, the binary still reads
`installed-files-shadow/etc/authserver.conf` at runtime because that's
its compiled-in default.

Verification:
```
$ strings installed-files-release/bin/authserver | grep installed-files
/home/ritz/games/azeroth-core/wow-chat-2026/installed-files-shadow/lib
/home/ritz/games/azeroth-core/wow-chat-2026/installed-files-shadow/etc
```

Authserver log confirms:
```
> Using configuration file  /home/ritz/games/azeroth-core/wow-chat-2026/installed-files-shadow/etc/authserver.conf
```

## Intended Behavior

When `scripts/authserver` (or `worldserver`) launches the promoted binary
without arguments, it reads its config from
`installed-files-${PROFILE}/etc/`. No flag should be needed for the
normal case. A flag (`-c`) would only be used to explicitly point at a
different conf — for example, when running the shadow binary during
validation.

## Suggested Implementation

The cleanest fix decouples the install prefix (where binaries land) from
the conf dir (where the binary looks for config at runtime).
AzerothCore's CMake exposes `CONF_DIR` as a separate cache variable.

In `scripts/compile`, change the cmake invocation so `CONF_DIR` points
at the profile-specific `etc/` rather than tracking the shadow prefix:

```bash
cmake "${AC_CODE_DIR}" \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR_SHADOW}" \
  -DCONF_DIR="${INSTALL_DIR}/etc" \    # add this — profile, not shadow
  ...
```

Where `INSTALL_DIR="${DIR}/installed-files-${PROFILE}"` (already set in
the script).

After this change, a fresh `--force` cmake reconfigure rebuilds the
binary with the profile-specific conf path baked in. Promote moves the
binary; the embedded path still points at the right etc directory.

## Validation

After applying:
```
$ strings installed-files-release/bin/authserver | grep installed-files-
/home/ritz/games/azeroth-core/wow-chat-2026/installed-files-release/etc
```

Authserver log should show:
```
> Using configuration file  /home/ritz/games/azeroth-core/wow-chat-2026/installed-files-release/etc/authserver.conf
```

## Edge Case (Resolved)

The shadow-validation run (started by `scripts/validate`) needs to load
`installed-files-shadow/etc/worldserver.conf`, not the promoted profile's
config. Validate launches the shadow binary directly; the shadow
binary's compiled-in CONF_DIR points at the *profile* etc after the
fix above, which would be wrong for validation.

**Fix applied:** `scripts/validate` passes
`-c "${INSTALL_DIR_SHADOW}/etc/worldserver.conf"` explicitly when
launching the shadow worldserver. The flag is the *exception*, used
precisely for the validation case where the binary must read shadow
config rather than the promoted-profile config.

## Related Files

- `scripts/compile` (cmake invocation around line 262)
- `scripts/authserver`, `scripts/worldserver` (no change needed if fix
  is applied at compile time)
- `scripts/validate` (will need explicit `-c` flag for shadow run)

## Related Issues

- 400 release-to-beta-transition (defines the build-shadow-then-promote
  workflow)
- 401 shadow-build-setup (completed; established the shadow concept)
- 408 release-profile-build-fixes (related cleanup)

## Update 2026-05-20: Module Configs Were Still Wrong

The "Edge Case (Resolved)" section above was incomplete. The `-c` flag
overrides only the *main* config file (`worldserver.conf`). Module
config files (`etc/modules/<name>.conf`) are loaded by `ConfigMgr`
via a separate code path:

```cpp
// Config.cpp:766
std::string const& moduleConfigPath = GetConfigPath() + "modules/";
```

And `GetConfigPath()` returns `_CONF_DIR + "/"` — the cmake-baked
literal, not the `-c` argument. So shadow validation ran the shadow
worldserver binary with the shadow `worldserver.conf` (correct) but
loaded module configs from `installed-files-release/etc/modules/`
(stale, uncustomised).

**How it surfaced.** The post-recompile validation run on 2026-05-20
crashed with `Access denied for user 'acore'@'localhost'` during
`DatabasePool Playerbots NOT opened`. The shadow `playerbots.conf` had
the correct `ritz/menardi` credentials patched in by C001, but the
binary was reading the release tree's `playerbots.conf` — which still
held the upstream defaults `acore;acore;acore_playerbots`. The user `acore`
doesn't exist, hence the access-denied error.

This means *every* C-patched module config has been invisible to
shadow validation since the shadow flow began. Playerbots was just
the loudest canary because its DB connection is mandatory at startup.

## B022: Runtime Conf-Dir Override (2026-05-20)

`patches/B022-runtime-conf-dir-override.sh` adds a `--conf-dir / -C`
CLI argument to all three apps (authserver, worldserver, dbimport)
and a `ConfigMgr::SetConfigPathOverride(path)` setter. When the arg
is non-empty, `GetConfigPath()` returns the override instead of the
baked `_CONF_DIR`. When the arg is absent (the normal release case),
behaviour is unchanged.

The patch uses the new **marker-comment convention** for invertible
multi-line insertions: every inserted block is wrapped in
`// {{{ B022-conf-dir-override` / `// }}} B022-conf-dir-override`.
The unpatch step deletes everything between those markers — one sed
per file, regardless of how many insertions. Because the markers
contain the patch ID, they cannot false-match upstream code or any
other B-patch. This is the established defence against the
`MailAction.cpp` self-inflicted drift documented in issue 126.

`scripts/validate` now passes both `-c shadow/etc/worldserver.conf`
*and* `-C shadow/etc`, so the shadow worldserver finally reads the
shadow tree's module configs during validation. The release runtime
invocation is unchanged: no flags, fallback to baked `_CONF_DIR`,
which points at the profile's `etc/` per the original fix above.

### Affected Source Files

- `src/common/Configuration/Config.h` — declaration of setter
- `src/common/Configuration/Config.cpp` — storage in the anonymous
  namespace, override check in `GetConfigPath()`, new setter impl
- `src/server/apps/worldserver/Main.cpp` — `--conf-dir` option + wiring
- `src/server/apps/authserver/Main.cpp` — same
- `src/tools/dbimport/Main.cpp` — same (symmetry for future tools that
  may load module configs; dbimport doesn't itself load any today)

### Verification

After applying B022 and rebuilding:

```bash
# release runtime: no override, baked _CONF_DIR wins
./worldserver
# > Using configuration file  /.../installed-files-release/etc/worldserver.conf
# module configs from  /.../installed-files-release/etc/modules/

# shadow validation: -C overrides both worldserver.conf and modules dir
./worldserver -c shadow/etc/worldserver.conf -C shadow/etc
# > Using configuration file  /.../installed-files-shadow/etc/worldserver.conf
# module configs from  /.../installed-files-shadow/etc/modules/
```

The Playerbots DB pool should now open cleanly during validation,
because the shadow `playerbots.conf` (patched to `ritz/menardi` by
C001) is finally the file the binary reads.
