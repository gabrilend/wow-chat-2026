# Installation Guide

## Prerequisites

- Linux system (Void Linux tested)
- Clang compiler toolchain
- CMake 3.16+
- Git
- MySQL server (custom build at `${DIR}/mysql/`)

## Quick Start

Active profile lives in `.profile` at the project root (`vanilla`, `alpha`,
`release`, or `beta`). All scripts read it from there. See
`issues/136-canonical-profile-definitions.md` for the canonical profile model
and `issues/148-vanilla-profile-default-wotlk-playerbots.md` for the vanilla
ruleset specification.

```bash
# Switch profile (writes .profile and reconfigures symlinks)
./scripts/switch release

# Fresh installation
./scripts/install

# Update an existing installation
./scripts/update
```

## Installation Process

`./scripts/install` performs:

1. **Source acquisition**
   - Clones AzerothCore into `source-{profile}/`
   - Clones required modules into `source-{profile}/modules/`

2. **Build**
   - Configures CMake with profile-local paths
   - Compiles with Clang (parallel)
   - Installs to `installed-files-{profile}/`

3. **Patches** (applied automatically by `apply-patches`)
   - B-patches modify upstream source pre-compile (reverted after build)
   - C-patches tune the runtime configs post-promote
   - See `docs/patches/patch-registry.md` for the full pipeline

4. **Database setup**
   - Creates MySQL databases (acore_auth, acore_world, acore_characters,
     acore_playerbots)
   - Configures user permissions

5. **Symlinks**
   - Links custom Lua scripts under `installed-files-{profile}/bin/lua_scripts/`
   - Links SQL customization scripts

## Running the Server

MySQL must be started first (the C-patches read connection strings from
`secrets.conf`):

```bash
./scripts/start-mysql

# Terminal 1
./scripts/authserver

# Terminal 2
./scripts/worldserver
```

## Database Management

Keira3 database editor:

```bash
./scripts/keira
```

## Configuration Files

| File | Purpose |
|------|---------|
| `installed-files-{profile}/etc/authserver.conf` | Login server settings |
| `installed-files-{profile}/etc/worldserver.conf` | Game world settings, rates, features |
| `secrets.conf` | Database credentials (gitignored) |

Per-module configs live under `installed-files-{profile}/etc/modules/`. The
release/beta profiles ship `mod_ale.conf` and `mod_playerbots.conf`.

## Data Files

Game data must be extracted from a WoW 3.3.5a client and placed in:

```
${DIR}/data-files/
```

Required subdirectories:
- `dbc/`
- `maps/`
- `vmaps/`
- `mmaps/`
- `cameras/` (optional)

## Troubleshooting

### Validator: check the server binary

```bash
./installed-files-${PROFILE}/bin/worldserver --version
```

### Validator: check database connectivity

```bash
./mysql/installed-files/bin/mysql \
  -u ritz -p \
  --socket=./mysql/databases/mysql.sock \
  -e "SHOW DATABASES;"
```

### Common Issues

**Build fails with missing headers**
- Ensure MySQL include path is correct in cmake command

**Server crashes on startup**
- Check `logs-{profile}/Errors.log` for specifics
- Verify data files are extracted correctly

**Cannot connect from client**
- Verify realmlist row in `acore_auth.realmlist` (C011 sets this)
- Check firewall rules for the configured auth/world ports (C010)
