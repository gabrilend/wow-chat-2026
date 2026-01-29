# Architecture Overview

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
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │ mod-eluna   │  │mod-playerbots│ │ mod-aoe-loot│   │  │
│  │  │ (LuaJIT)    │  │             │  │             │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │  │
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
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Authentication Flow
1. Client connects to authserver on port 3724
2. Authserver validates credentials against acore_auth
3. Client receives realm list
4. Client connects to worldserver on port 8085

### Game Loop
1. World server runs at configurable tick rate
2. Each tick processes: movement, combat, spells, AI
3. Eluna hooks fire at appropriate event points
4. Lua scripts execute within the tick budget

### Script Execution
1. Server loads Lua scripts from lua_scripts/ directory
2. Scripts register event handlers via Eluna API
3. Events trigger Lua callbacks synchronously
4. Scripts can query/modify game state through Eluna bindings

## Directory Layout

```
installed-files/
├── bin/
│   ├── authserver          # Authentication daemon
│   ├── worldserver         # Game world daemon
│   └── lua_scripts/        # Eluna script directory
│       ├── custom/         # Symlink to shared custom scripts
│       └── extensions/     # Symlink to shared extensions
├── etc/
│   ├── authserver.conf     # Auth configuration
│   ├── worldserver.conf    # World configuration
│   └── modules/            # Module-specific configs
├── lib/                    # Shared libraries
└── share/                  # LuaJIT standard library
```

## Module Integration Points

### mod-eluna
- Hooks into 200+ server events
- Provides Lua bindings for game objects
- Scripts loaded from lua_scripts/ subdirectories

### mod-playerbots
- AI decision trees for bot behavior
- Party/raid formation logic
- Quest and combat automation

### mod-aoe-loot
- Modifies loot distribution system
- Area-based item collection

### mod-grownup
- Level scaling calculations
- XP rate modifications
