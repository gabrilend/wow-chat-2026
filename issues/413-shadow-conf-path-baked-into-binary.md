# 413 - Shadow Conf Path Baked Into Binary

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
