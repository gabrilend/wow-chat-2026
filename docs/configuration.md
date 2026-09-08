# Configuration Reference

This document describes all configuration options for wow-chat-2026, including server settings,
module configurations, Lua script constants, and MySQL settings. Paths use
`{profile}` as a placeholder for the active profile (read from `.profile`
at the project root: `vanilla`, `alpha`, `release`, or `beta`). See
`issues/136-canonical-profile-definitions.md` for what each profile means.

## Quick Reference

| Config File | Purpose | Restart Required |
|-------------|---------|------------------|
| `installed-files-{profile}/etc/authserver.conf` | Login server | Yes |
| `installed-files-{profile}/etc/worldserver.conf` | Game server | Most settings |
| `installed-files-{profile}/etc/modules/mod_ale.conf` | Lua scripting engine | Yes |
| `scripts/mysql-install` | Database server settings (generates my.cnf) | Yes |
| `src/lua/periodic_events.lua` | Game loop timings | `.reload ale` |
| `secrets.conf` | Database credentials | Yes |

---

## Path Configuration

All paths are configured to be local to the project directory.

### authserver.conf

| Setting | Value | Purpose |
|---------|-------|---------|
| `LogsDir` | `/mnt/mtwo/.../wow-chat-2026/logs-{profile}` | Authentication logs |
| `SourceDirectory` | `/mnt/mtwo/.../wow-chat-2026/source-{profile}` | AzerothCore source |
| `MySQLExecutable` | `/mnt/mtwo/.../wow-chat-2026/mysql/installed-files/bin/mysql` | Local MySQL client |
| `LoginDatabaseInfo` | `127.0.0.1;3307;ritz;***;acore_auth` | Database connection |

### worldserver.conf

| Setting | Value | Purpose |
|---------|-------|---------|
| `DataDir` | `/mnt/mtwo/.../wow-chat-2026/data-files` | DBC, maps, vmaps, mmaps |
| `LogsDir` | `/mnt/mtwo/.../wow-chat-2026/logs-{profile}` | Server logs |
| `BuildDirectory` | `/mnt/mtwo/.../wow-chat-2026/build-{profile}` | CMake build dir |
| `SourceDirectory` | `/mnt/mtwo/.../wow-chat-2026/source-{profile}` | AzerothCore source |
| `MySQLExecutable` | `/mnt/mtwo/.../wow-chat-2026/mysql/installed-files/bin/mysql` | Local MySQL client |

---

## Database Configuration

### Connection Settings

All three databases connect to the local MySQL instance on port 3307:

| Database | Setting | Connection String |
|----------|---------|-------------------|
| Auth | `LoginDatabaseInfo` | `127.0.0.1;3307;ritz;***;acore_auth` |
| World | `WorldDatabaseInfo` | `127.0.0.1;3307;ritz;***;acore_world` |
| Characters | `CharacterDatabaseInfo` | `127.0.0.1;3307;ritz;***;acore_characters` |

Credentials are stored in `secrets.conf` (gitignored).

### MySQL Configuration (written by scripts/mysql-install)

The file the server reads is `mysql/conf/my.cnf`, and it is generated
rather than edited. The settings live inside `scripts/mysql-install`,
which writes them out with this project's absolute path substituted
into the seven places that need it — the base directory, the data
directory, the temp directory, the socket, and three log paths.

They live inside the script rather than in a template file so that a
copy of `scripts/mysql-install` downloaded on its own, onto a machine
that has never seen this project, can still set up a working server.
That is also what fixed the problem in issue 154: `my.cnf` used to be
tracked in git with one machine's absolute paths in it, so any copy
taken elsewhere started a server pointed at directories that did not
exist there.

To change a setting, change it in that script and run
`scripts/mysql-install --regenerate-config`. The installer also
rewrites the file on its own when it finds one whose paths resolve
somewhere other than the current project, keeping the old one beside it
as `my.cnf.bak`. Paths are compared after resolving symlinks, so a
project reachable by more than one route is not mistaken for a move.

| Setting | Value | Purpose |
|---------|-------|---------|
| `port` | `3307` | Avoids conflict with system MySQL |
| `socket` | `mysql/databases/mysql.sock` | Unix socket path |
| `datadir` | `mysql/databases/` | Database files |
| `innodb_buffer_pool_size` | `256M` | Memory for InnoDB |
| `innodb_redo_log_capacity` | `128M` | Redo log size (MySQL 9.x) |
| `character-set-server` | `utf8mb4` | Unicode support |

---

## Game Settings

### Realm Configuration

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `GameType` | 0 (Normal) | 6 (RPPVP) | Realm type |
| `RealmZone` | 1 (US) | 2 (Korea) | Timezone region |
| `BirthdayTime` | (varies) | 1756342283 | Anniversary calculations |

### Movement and Combat

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Rate.MoveSpeed.Player` | 1.0 | **0.85** | Slower player movement |
| `Rate.MoveSpeed.NPC` | 1.0 | **0.85** | Slower NPC movement |
| `Rate.Damage.Fall` | 1.0 | **8.0** | Increased fall damage |
| `WaterBreath.Timer` | 180000 | **30000** | 30s breath (was 3min) |

### Experience and Progression

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Rate.Talent` | 1 | **3** | 3x talent points |
| `Rate.Talent.Pet` | 1 | **3** | 3x pet talent points |
| `EnableLowLevelRegenBoost` | 1 | **0** | Disabled low-level regen |

### Rested XP

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Rate.Rest.InGame` | 1 | **10** | 10x rest accumulation |
| `Rate.Rest.Offline.InTavernOrCity` | 1 | **5** | 5x offline rest |
| `Rate.Rest.MaxBonus` | 1.5 | **10** | Max 10x rested bonus |

### Combat Accuracy

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Rate.MissChanceMultiplier.TargetCreature` | 11 | **1** | Reduced miss chance vs NPCs |
| `Rate.MissChanceMultiplier.TargetPlayer` | 7 | **1** | Reduced miss chance vs players |

### Economy

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Rate.SellValue.Item.Normal` | 1 | **2** | 2x vendor value |
| `Rate.SellValue.Item.Uncommon` | 1 | **3** | 3x green vendor value |
| `Rate.SellValue.Item.Rare` | 1 | **4** | 4x blue vendor value |
| `Rate.SellValue.Item.Epic` | 1 | **5** | 5x purple vendor value |
| `Rate.SellValue.Item.Legendary` | 1 | **10** | 10x orange vendor value |
| `Rate.RepairCost` | 1 | **25** | 25x repair costs |
| `MaxPrimaryTradeSkill` | 2 | **1** | Only 1 primary profession |

### Death and Corpse

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Death.SicknessLevel` | 11 | **255** | No rez sickness |
| `Death.CorpseReclaimDelay.PvE` | 1 | **0** | Instant corpse reclaim |
| `Corpse.Decay.NORMAL` | 60 | **3600** | 1hr corpse decay |
| `Corpse.Decay.RARE` | 300 | **3600** | 1hr rare decay |
| `Corpse.Decay.ELITE` | 300 | **3600** | 1hr elite decay |

### Creatures

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `CreatureLeashRadius` | 30 | **0** | No leash (chase forever) |
| `CreatureFamilyAssistanceRadius` | 10 | **30** | Larger aggro assist |
| `CreatureFamilyFleeAssistanceRadius` | 30 | **60** | Larger flee assist |

### Visibility

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Visibility.Distance.Continents` | 100 | **250** | Extended view distance |
| `Visibility.GroupMode` | 1 | **0** | Disabled group mode |
| `Visibility.ObjectSparkles` | 1 | **0** | No quest sparkles |
| `Visibility.ObjectQuestMarkers` | 1 | **0** | No quest markers |

### Line of Sight

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `vmap.BlizzlikePvPLOS` | 1 | **0** | Relaxed PvP LoS |
| `vmap.BlizzlikeLOSInOpenWorld` | 1 | **0** | Relaxed open world LoS |

### Quests

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `QuestPOI.Enabled` | 1 | **0** | No quest points of interest |
| `Quests.LowLevelHideDiff` | 4 | **-1** | Show all low-level quests |
| `Quests.HighLevelHideDiff` | 7 | **-1** | Show all high-level quests |
| `Quests.IgnoreRaid` | 0 | **1** | Solo raid quests |

### Instances

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Instance.IgnoreLevel` | 0 | **1** | Enter dungeons at any level |
| `Instance.IgnoreRaid` | 0 | **1** | Solo raids |
| `Group.Raid.LevelRestriction` | 10 | **1** | Minimal raid level diff |
| `DungeonAccessRequirements.PrintMode` | 1 | **2** | Verbose dungeon info |

### Dungeon Finder

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `DungeonFinder.OptionsMask` | 5 | **0** | Disabled LFD options |
| `DungeonFinder.CastDeserter` | 1 | **0** | No deserter debuff |

### Cross-Faction

All cross-faction interactions enabled:

| Setting | Default | Current |
|---------|---------|---------|
| `AllowTwoSide.Interaction.Chat` | 0 | **1** |
| `AllowTwoSide.Interaction.Channel` | 0 | **1** |
| `AllowTwoSide.Interaction.Group` | 0 | **1** |
| `AllowTwoSide.Interaction.Guild` | 0 | **1** |
| `AllowTwoSide.Interaction.Trade` | 0 | **1** |
| `AllowTwoSide.Interaction.Auction` | 0 | **1** |
| `AllowTwoSide.Interaction.Mail` | 0 | **1** |
| `AllowTwoSide.AddFriend` | 0 | **1** |
| `AllowTwoSide.WhoList` | 0 | **1** |

### Guilds

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `MinPetitionSigns` | 9 | **0** | Solo guild creation |
| `Guild.CharterCost` | 1000 | **100000000** | 10k gold charter |
| `Guild.AllowMultipleGuildMaster` | 0 | **1** | Multiple GMs allowed |
| `Guild.BankInitialTabs` | 0 | **1** | Start with 1 bank tab |

### PvP

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `Wintergrasp.Enable` | 1 | **2** | Wintergrasp mode 2 |
| `Battleground.PrepTime` | 120 | **30** | 30s prep time |
| `Battleground.CastDeserter` | 1 | **0** | No BG deserter |
| `Battleground.QueueAnnouncer.Enable` | 0 | **1** | BG queue announcements |
| `Battleground.GiveXPForKills` | 0 | **1** | XP from BG kills |

### Other Settings

| Setting | Default | Current | Purpose |
|---------|---------|---------|---------|
| `CloseIdleConnections` | 1 | **0** | Keep idle connections |
| `PreventAFKLogout` | 0 | **1** | Prevent AFK logout |
| `EnablePlayerSettings` | 0 | **1** | Enable player settings |
| `PlayerSave.Stats.SaveOnlyOnLogout` | 1 | **0** | Save stats periodically |
| `CharDelete.Method` | 0 | **1** | Soft delete characters |
| `StrictNames.Reserved` | 1 | **0** | Allow reserved names |
| `StrictNames.Profanity` | 1 | **0** | Allow profanity |
| `DBC.EnforceItemAttributes` | 1 | **0** | Relaxed item attributes |

---

## Module Configuration

### ALE (mod_ale.conf)

| Setting | Value | Purpose |
|---------|-------|---------|
| `ALE.Enabled` | true | LuaJIT scripting enabled |
| `ALE.TraceBack` | false | Standard error output |
| `ALE.ScriptPath` | "lua_scripts" | Script directory |
| `ALE.AutoReload` | false | Manual reload only |
| `ALE.BytecodeCache` | true | Cached compilation |

Scripts are loaded from:
- `installed-files-{profile}/bin/lua_scripts/custom/` - Game logic scripts
- `installed-files-{profile}/bin/lua_scripts/extensions/` - Utility libraries

Reload scripts with: `.reload ale`

(The legacy `alpha` profile uses `mod_eluna.conf` with the same setting keys
under the `Eluna.` namespace and reloads via `.reload eluna`.)

---

## Lua Script Configuration

Game loop timing constants in `src/lua/periodic_events.lua`:

| Constant | Value | Purpose |
|----------|-------|---------|
| `DELAY_PERIODIC_SPAWN_CREATURE` | 40000 (40s) | Ambush spawn interval |
| `DELAY_PERIODIC_SPAWN_TRAVELLER` | 130000 (130s) | Traveller spawn interval |
| `DELAY_PERIODIC_SPAWN_TREASURE` | 100000 (100s) | Treasure spawn interval |

### Ambush System (src/lua/ambush.lua)

| Setting | Value | Purpose |
|---------|-------|---------|
| `ambush_min_distance` | 120 | Minimum spawn distance |
| `ambush_max_distance` | 160 | Maximum spawn distance |
| `MaxQueueSize` | 8 | Creatures per queue |
| `max-ambushers` (data) | 3 | Max concurrent ambushers |

### Treasure System (src/lua/treasure.lua)

| Setting | Value | Purpose |
|---------|-------|---------|
| `treasureMinDist` | 20 | Minimum spawn distance |
| `treasureMaxDist` | 35 | Maximum spawn distance |

### Tempo System (src/lua/tempo.lua)

| Constant | Value | Purpose |
|----------|-------|---------|
| `RHYTHM_MAX` | 1 | Maximum tempo value |
| `RHYTHM_MIN` | 0 | Minimum tempo value |
| `RHYTHM_INTERVAL` | 500 (0.5s) | Tempo update interval |

---

## Configuration Files Location

```
wow-chat-2026/
├── installed-files-{profile}/etc/
│   ├── authserver.conf          # Login server config
│   ├── worldserver.conf         # World server config (main game settings)
│   └── modules/
│       └── mod_ale.conf         # Lua scripting engine (mod_eluna.conf on alpha)
├── mysql/conf/
│   └── my.cnf                   # MySQL server config, written per machine
│                                #   by scripts/mysql-install
├── src/lua/
│   ├── periodic_events.lua      # Game loop timings
│   ├── ambush.lua               # Ambush distances
│   ├── treasure.lua             # Treasure distances
│   └── tempo.lua                # Tempo/rhythm settings
└── secrets.conf                 # Database credentials (gitignored)
```

---

## Modifying Configuration

### Server Config Changes

1. Edit the relevant `.conf` file
2. Restart the server (most settings require restart)
3. Some settings support `.reload config` in-game

### Lua Script Changes

1. Edit files in `src/lua/`
2. `installed-files-{profile}/bin/lua_scripts/custom/` is a symlink back to
   `src/lua/`, so edits are visible immediately
3. Run `.reload ale` in-game (no server restart needed; `.reload eluna` on alpha)

### Database Changes

1. Stop MySQL: `./scripts/stop-mysql`
2. Edit the settings in `scripts/mysql-install` (its `write_server_config`)
3. Regenerate the config: `./scripts/mysql-install --regenerate-config`
4. Start MySQL: `./scripts/start-mysql`

Editing `mysql/conf/my.cnf` directly works until the next regeneration,
which replaces it. The copy inside the script is the one that lasts.

---

## Related Documents

- [Installation Guide](installation.md) - Server setup procedures
- [Scripting Reference](scripting.md) - Lua API documentation
- [Architecture](architecture.md) - System design overview
