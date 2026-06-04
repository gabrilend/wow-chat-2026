# Everland Ghostsong - Architecture Overview

*Technical name: wow-chat-2026*

## System Components

```
┌─────────────────────────────────────────────────────────────┐
│                      WoW Client (3.3.5a)                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Auth Server                            │
│  • Handles login authentication                              │
│  • Realm list management                                     │
│  • Account verification                                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      World Server                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    Core Engine                       │    │
│  │  • Game loop and tick management                     │    │
│  │  • Entity management (players, NPCs, objects)        │    │
│  │  • Combat, movement, spell systems                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                               │
│  ┌───────────────────────────┼───────────────────────────┐  │
│  │                           ▼                           │  │
│  │  ┌─────────────────┐         ┌──────────────────┐    │  │
│  │  │   mod-ale       │         │  mod-playerbots  │    │  │
│  │  │   (LuaJIT)      │         │                  │    │  │
│  │  └─────────────────┘         └──────────────────┘    │  │
│  │                   Module Layer                        │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         MySQL                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐      │
│  │ acore_auth  │  │ acore_world │  │ acore_characters│      │
│  └─────────────┘  └─────────────┘  └─────────────────┘      │
│  ┌──────────────────┐                                       │
│  │ acore_playerbots │                                       │
│  └──────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
```

The two structural modules — **mod-ale** and **mod-playerbots** — define
the project. ALE provides the Lua surface that wow-chat behaviors hook
into; playerbots fill the world with AI companions and dictates which
AzerothCore fork the release/beta profiles build against. Other modules
may be present on disk per-profile but are not architecturally load-bearing.

## Data Flow

### Authentication Flow
1. Client connects to authserver on the configured auth port (C010)
2. Authserver validates credentials against `acore_auth`
3. Client receives realm list (row written by C011)
4. Client connects to worldserver on the configured world port (C010)

### Game Loop
1. World server runs at configurable tick rate
2. Each tick processes: movement, combat, spells, AI
3. ALE hooks fire at appropriate event points
4. Lua scripts execute within the tick budget

### Script Execution
1. Server loads Lua scripts from the `lua_scripts/` directory
2. Scripts register event handlers via the ALE API
3. Events trigger Lua callbacks synchronously
4. Scripts can query/modify game state through ALE bindings

## Directory Layout

```
installed-files-{profile}/
├── bin/
│   ├── authserver          # Authentication daemon
│   ├── worldserver         # Game world daemon
│   └── lua_scripts/        # ALE script directory
│       ├── custom/         # Symlink to shared custom scripts
│       └── extensions/     # Symlink to shared extensions
├── etc/
│   ├── authserver.conf     # Auth configuration
│   ├── worldserver.conf    # World configuration
│   └── modules/            # Module-specific configs
├── lib/                    # Shared libraries
└── share/                  # LuaJIT standard library
```

Each profile has its own isolated tree (`installed-files-alpha/`,
`installed-files-release/`, `installed-files-beta/`). The active profile is
named in `.profile` at the project root.

## Module Integration Points

### mod-ale
- Hooks into 200+ server events
- Provides Lua bindings for game objects
- Scripts loaded from `lua_scripts/` subdirectories
- The Lua surface for everything in `src/lua/`

### mod-playerbots
- AI decision trees for bot behavior
- Party/raid formation logic
- Quest and combat automation
- The fork choice; pins which AzerothCore source tree is built
