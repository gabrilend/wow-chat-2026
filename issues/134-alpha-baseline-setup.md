# 134 - Alpha Baseline Setup

## Status
- Created: 2026-04-10
- Completed: 2026-04-10
- Priority: Critical
- Phase: Foundation

## Goal

Establish `source-alpha/` as the known-good regression point based on wow-chat-1.

## Alpha Profile Definition

**Alpha = wow-chat-1 baseline**
- Earliest safe regression point
- Old Eluna Lua engine
- Minimal features, proven stable
- Always works

## Setup Completed

### AzerothCore Base

```bash
cd /mnt/mtwo/games/azeroth-core/wow-chat-2026
git clone https://github.com/azerothcore/azerothcore-wotlk.git source-alpha
cd source-alpha
git checkout 5af3d2d6
git switch -c alpha-baseline
```

**Commit:** `5af3d2d6` - fix(Scripts/BlackTemple): Flames of Azzinoth

**Source:** Same commit as /home/ritz/games/azeroth-core/azerothcore/

### Modules Added

```bash
cd source-alpha/modules
git clone https://github.com/azerothcore/mod-eluna.git
git clone https://github.com/azerothcore/mod-transmog.git
```

**Modules:**
- mod-eluna: Lua scripting engine (Eluna)
- mod-transmog: Transmogrification system

### Final Structure

```
source-alpha/
  ├── src/              (AzerothCore 5af3d2d6)
  ├── modules/
  │   ├── mod-eluna/    (Eluna Lua engine)
  │   └── mod-transmog/ (Transmog system)
  └── data/
```

## Profile Configuration

Located in: `scripts/azerothcore` line 30-89

```bash
PROFILE_REPO["alpha"]="https://github.com/azerothcore/azerothcore-wotlk.git"
PROFILE_BRANCH["alpha"]="master"
PROFILE_MODULES["alpha"]="mod-eluna;mod-transmog"
```

## Build/Install Directories

- Source: `source-alpha/`
- Build: `build-alpha/`
- Install: `installed-files-alpha/`
- Config: `config/alpha/`

## Lua Scripts

Alpha-specific Lua scripts use `.alpha.lua` suffix:
- `src/lua/*.alpha.lua` - Will be loaded when `.current-profile = "alpha"`

## Patches

Alpha-specific patches use `alpha-` prefix:
- `patches/alpha-*.sh` - Applied only for alpha profile

## Next Steps

- [ ] Build alpha profile: `echo "alpha" > .current-profile && ./scripts/azerothcore update`
- [ ] Test alpha server starts
- [ ] Validate Eluna Lua scripts load
- [ ] Document known-working state
- [ ] Use as regression baseline when beta breaks

## Validation Checklist

Server must:
- [x] Source cloned at correct commit
- [x] mod-eluna present
- [x] mod-transmog present
- [ ] Compile successfully
- [ ] Start authserver
- [ ] Start worldserver
- [ ] Load Eluna scripts
- [ ] Accept client connections
- [ ] No crashes for 5 minutes

## Notes

This is the fallback position. When beta experiments break things, we can always return to alpha and know it works.

**Alpha must always work.** No exceptions.

If alpha breaks, stop everything and fix it immediately.

## Related Files

- `scripts/azerothcore` - Profile routing logic
- `docs/profile-transition-flow.md` - Profile system design
- `issues/133-profile-transition-system.md` - Implementation plan (was 405; superseded by 136)

## Completion Notes

Alpha baseline established at AzerothCore commit 5af3d2d6 with mod-eluna and mod-transmog. This matches the wow-chat-1 installation and provides a known-good regression point.

Next: Validate by building and running the alpha profile.
