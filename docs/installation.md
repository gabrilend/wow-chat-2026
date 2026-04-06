# Installation Guide

## Prerequisites

- Linux system (Void Linux tested)
- Clang compiler toolchain
- CMake 3.16+
- Git
- MySQL server (custom build at /home/ritz/programs/mysql-server/)

## Quick Start

```bash
# Source the azerothcore script
source /home/ritz/games/azeroth-core/wow-chat-2026/scripts/azerothcore

# Fresh installation
azerothcore install

# Update existing installation
azerothcore update
```

## Installation Process

The `install-azerothcore` function performs:

1. **Source Acquisition**
   - Clones the Playerbot-enabled AzerothCore fork
   - Clones required modules into source/modules/

2. **Build**
   - Configures CMake with custom paths
   - Compiles with Clang (-j15 parallel)
   - Installs to installed-files/

3. **Database Setup**
   - Creates MySQL databases (acore_auth, acore_world, acore_characters)
   - Configures user permissions

4. **Configuration**
   - Copies .conf.dist files to .conf
   - Patches database connection strings
   - Sets directory paths for logs, data, source

5. **Symlinks**
   - Links custom Lua scripts
   - Links SQL customization scripts

## Running the Server

```bash
# Terminal 1: Start auth server
source /home/ritz/games/azeroth-core/wow-chat-2026/scripts/azerothcore
authserver

# Terminal 2: Start world server
source /home/ritz/games/azeroth-core/wow-chat-2026/scripts/azerothcore
worldserver
```

## Database Management

Keira database editor available:
```bash
source /home/ritz/games/azeroth-core/wow-chat-2026/scripts/azerothcore
keira
```

## Configuration Files

| File | Purpose |
|------|---------|
| authserver.conf | Login server settings |
| worldserver.conf | Game world settings, rates, features |
| mod_grownup.conf | Level scaling options |

## Data Files

Game data must be extracted from a WoW 3.3.5a client and placed in:
```
/home/ritz/games/azeroth-core/wowchat-2025/data-files/
```

Required data:
- dbc/
- maps/
- vmaps/
- mmaps/
- cameras/ (optional)

## Troubleshooting

### Validator: run server binary with --version to check build
```bash
./installed-files/bin/worldserver --version
```

### Validator: check database connectivity
```bash
/home/ritz/programs/mysql-server/installed-files/bin/mysql \
  -u ritz -p \
  --socket=/home/ritz/programs/mysql-server/databases/mysql.sock \
  -e "SHOW DATABASES;"
```

### Common Issues

**Build fails with missing headers**
- Ensure MySQL include path is correct in cmake command

**Server crashes on startup**
- Check logs/Errors.log for specifics
- Verify data files are extracted correctly

**Cannot connect from client**
- Verify realmlist in acore_auth.realmlist table
- Check firewall rules for ports 3724, 8085
