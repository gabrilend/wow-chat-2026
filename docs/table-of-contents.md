# Documentation Table of Contents

## Project Root
```
wow-chat-2/
├── docs/
│   ├── table-of-contents.md    [this file]
│   ├── architecture.md         System architecture and data flow
│   ├── configuration.md        Configuration options reference
│   ├── installation.md         Setup and installation guide
│   ├── scripting.md            Eluna Lua scripting reference
│   ├── roadmap.md              Development phases and milestones
│   └── delta-guide.md          -> (symlink) Monorepo methodology
│
├── notes/
│   └── vision                  Project vision and goals
│
├── issues/
│   ├── phase-1-progress.md     Phase 1 completion status
│   └── completed/              Resolved issues archive
│       └── demos/              Phase demonstration scripts
│
├── src/                        Custom Lua source code
├── libs/                       Shared utility libraries
├── assets/                     Static assets and SQL scripts
│
├── scripts/
│   ├── azerothcore             Server management functions
│   └── update                  System update utilities
│
├── installed-files/            Compiled server binaries
├── logs/                       Runtime log files
├── build/                      CMake build artifacts
└── source/                     AzerothCore source (when cloned)
```

## Document Hierarchy

### Core Documentation
1. **notes/vision** - Project purpose and direction
2. **docs/architecture.md** - Technical design overview
3. **docs/roadmap.md** - Development phases

### Operational Documentation
4. **docs/installation.md** - Setup procedures
5. **docs/configuration.md** - All server and script settings
6. **docs/scripting.md** - Lua API reference

### Process Documentation
7. **docs/delta-guide.md** - Issue tracking methodology
8. **issues/phase-X-progress.md** - Phase completion tracking

## Adding New Documents

When creating new documentation:
1. Add the file to the appropriate directory
2. Update this table of contents
3. Commit with message describing the new document

## Related External Documents

- AzerothCore Wiki: https://www.azerothcore.org/wiki/
- Eluna Documentation: https://elunaluaengine.github.io/
- LuaJIT Reference: https://luajit.org/luajit.html
