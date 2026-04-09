# Connection Guide for Players

## TL;DR

1. **Get the WoW 3.3.5a client** - Search "WoW 3.3.5a client download"

2. **Install the AIO addon** - Download from https://github.com/Rochet2/AIO/releases
   and put the `AIO_Client` folder in `World of Warcraft/Interface/AddOns/`

3. **Edit your realmlist** - Open `realmlist.wtf` with Notepad, replace everything with:
   ```
   set realmlist wow.ritzmenardi.com:4362
   ```

Launch `Wow.exe` and play.

---

*Read on for security details and troubleshooting.*

---

Welcome to Everland Ghostsong. This guide walks you through connecting to our
server. Each step includes security notes so you understand exactly what you're
installing and why it's safe.


## Overview

Connecting requires three things:

1. **WoW 3.3.5a Client** - The game itself (read-only game files)
2. **AIO Addon** - Displays our custom UI elements (display-only)
3. **Realmlist Change** - Points your client to our server (one text edit)

None of these can harm your computer. Let's explain why.


## Security Model

### The Client is a Viewer

The WoW 3.3.5a client is a **read-only viewer**. It:

- Reads game data files (maps, textures, sounds)
- Sends your keyboard/mouse input to the server
- Displays what the server tells it to display

The client cannot:

- Write files outside its own directory
- Execute programs on your computer
- Access your documents, photos, or other files
- Install software or modify your system

Think of it like a web browser that only speaks one language (WoW protocol).
It shows you a world, but the world lives on the server.

### Server Customizations Stay on the Server

Our server has extensive custom mechanics: ambush spawns, AI companions,
roguelike survival elements. **All of this runs on the server.**

Your client receives the same data packets as any WoW 3.3.5a server would
send. It sees creatures spawn, items appear, abilities activate - but your
client doesn't know these are custom systems. It just renders what it's told.

The custom Lua scripts, spawn algorithms, and game logic never touch your
computer. They exist only on our server hardware.

### AIO: Display-Only Addon Framework

AIO (Addon Input/Output) lets our server send custom UI frames to your client.
This sounds scary until you understand what it actually does:

**What AIO does:**
- Receives UI layout instructions from the server
- Creates standard WoW addon frames (buttons, text, panels)
- Displays information calculated server-side

**What AIO cannot do:**
- Execute arbitrary code
- Access your filesystem
- Read files outside the WoW directory
- Modify your system in any way
- Run programs or scripts

AIO is a **rendering pipeline**, not a code execution engine. The server says
"draw a button at position X,Y with this text" and AIO draws it. The server
says "update this number to 42" and AIO updates the display.

All game logic, calculations, and decisions happen on the server. AIO just
shows you the results.


## Step 1: Obtain the WoW 3.3.5a Client

### What You Need

World of Warcraft version 3.3.5a (build 12340). This is the final patch of
the Wrath of the Lich King expansion, released in 2010.

### Where to Get It

We cannot distribute the client due to copyright. You'll need to:

- Use your existing WoW installation (if you have one from that era)
- Search for "WoW 3.3.5a client download" - many private server communities
  maintain downloads

### Verifying Your Client

After download, check the version:

1. Launch `Wow.exe`
2. Look at the bottom-left of the login screen
3. It should read: `3.3.5a (12340)`

If you see a different version, you have the wrong client.

### Security Note

The client executable (`Wow.exe`) is a standard Windows application from 2010.
It predates many modern attack vectors and has no network capabilities beyond
connecting to game servers. Antivirus software may flag it as "unknown" simply
because it's old - this is not a virus detection.

The client runs in user-space with no elevated privileges. It cannot modify
system files, install drivers, or affect other programs.


## Step 2: Install the AIO Addon

### What AIO Is

AIO (Addon Input/Output) is an addon framework that lets the server send
custom UI elements to your client. Many private servers use it for custom
quest logs, skill trees, and informational displays.

### Download Location

Download the AIO client addon from:
https://github.com/Rochet2/AIO

Direct link to releases:
https://github.com/Rochet2/AIO/releases

Download the `AIO_Client` folder.

### Installation

1. Locate your WoW directory (where `Wow.exe` lives)
2. Open the `Interface/AddOns/` folder
   - If `AddOns` doesn't exist, create it
3. Copy the `AIO_Client` folder into `AddOns/`

Your folder structure should look like:
```
World of Warcraft/
├── Wow.exe
├── Data/
└── Interface/
    └── AddOns/
        └── AIO_Client/
            ├── AIO_Client.lua
            ├── AIO_Client.toc
            └── ... (other files)
```

### Verify Installation

1. Launch WoW
2. At the character select screen, click "AddOns" (bottom left)
3. You should see "AIO_Client" in the list
4. Ensure it's checked/enabled

### Security Note

The AIO addon consists of standard Lua files that WoW's addon API executes.
WoW's addon sandbox is extremely restrictive:

- Addons cannot access files outside WoW's directory
- Addons cannot execute system commands
- Addons cannot open network connections (only the game client can)
- Addons cannot read your clipboard, keylog, or access other programs

AIO operates within this sandbox. It receives data through the game protocol
(the same channel that sends chat messages and combat updates) and uses
standard WoW API functions to create UI frames.

The "worst" thing AIO could theoretically do is draw annoying UI elements
on your screen - and you can always disable the addon.


## Step 3: Configure Your Realmlist

### What the Realmlist Does

The realmlist tells your client which server to connect to. By default, it
points to (non-functional) Blizzard servers. You need to change it to point
to our server.

### Editing the Realmlist

1. Open your WoW directory
2. Find `realmlist.wtf` (or `Data/enUS/realmlist.wtf` on some clients)
3. Open it with any text editor (Notepad, TextEdit, etc.)
4. Replace the contents with:

```
set realmlist wow.ritzmenardi.com:4362
```

5. Save the file

### Security Note

The realmlist is a plain text file containing only a server address. Editing
it is equivalent to typing a URL into your browser - you're just telling the
application where to connect.

The WoW client will only connect to the specified address using WoW's
authentication protocol. It cannot be tricked into downloading files,
executing code, or performing any action other than establishing a game
session.

If you connect to a malicious server, the worst that could happen is:
- You see inappropriate game content
- Your character on that server gets deleted (account is server-side)
- The server could crash your client (annoying, not harmful)

A malicious server cannot access your computer's files, install software,
or affect anything outside the game window. The protocol simply doesn't
support those operations.


## Step 4: Connect and Play

### First Launch

1. Launch `Wow.exe` directly

   **Important:** Do not use `Launcher.exe` or any Battle.net launcher. The
   launcher will attempt to update your client to a newer version, which breaks
   compatibility with 3.3.5a servers. Always launch `Wow.exe` directly.

2. You should see our server name on the realm list

3. Log in with a guest account or create your own

4. Create a character and play

### Guest Accounts

Guest accounts are available for trying the server. Pick any one:

| Username    | Password         |
|-------------|------------------|
| filament    | cherry-ribbon    |
| verbose     | table-aperture   |
| clock       | super-migration  |
| fable       | interest-sincere |
| raptor      | cannon-pilgrim   |
| flipper     | absolute-chatter |
| peculiar    | spectacle-taxes  |
| serenade    | mountain-pulse   |
| artifice    | affront-bulbous  |
| nostalgia   | unmitigated-butt |
| ephemeren   | reticulated-self |
| sorrowful   | falling-leaves   |
| testUser    | please-ignore    |
| riparian    | ossified-metrics |
| multitude   | harmonic-angles  |
| catlike     | arduous-flames   |
| aboleth     | ardent-forays    |
| mailbox     | deleted-shivers  |
| scarlet     | crusade-rocks    |
| fibrous     | crushed-parasol  |
| luminous    | frothy-waves     |
| seaweed     | protects-bears   |
| carbon      | blessing-cinders |
| sympathy    | motor-responses  |

Guest accounts are shared - your characters may be deleted at any time.

### Creating Your Own Account

Personal accounts are created through rmail, an encrypted messaging system.
See `docs/rmail-integration.md` for full setup instructions.

**Quick summary:**
1. Install rmail and add the `wow.ritzmenardi.com/accounts` contact
2. Send a message with your username on the first line, password on the second.
3. Your account exists as long as your message exists (delete message = delete account)

### If You Can't Connect

Common issues:

**"Unable to connect"**
- Check your internet connection
- Verify the realmlist address is correct
- The server may be down for maintenance
- Poke Ritz to turn the server on (it's probably off)
- If I don't answer it's because I'm asleep or in Vancouver or something.

**"Disconnected from server"**
- I'm probably recompiling the server with changes.
- A quick update is ~5 minutes, a long one is ~20.
- If it's not that, try deleting the `Cache` folder in your WoW directory

**Addon not working**
- Verify AIO_Client is in the correct folder
- Check that it's enabled in the AddOns menu
- Type `/reload` in-game to reload addons


## Summary of What's on Your Computer

After setup, you have:

| Component | Location | What It Does | Security |
|-----------|----------|--------------|----------|
| WoW Client | Your chosen folder | Renders the game world | Sandboxed viewer, no system access |
| AIO Addon | WoW/Interface/AddOns/ | Displays server-sent UI | WoW addon sandbox, display-only |
| Realmlist | WoW/realmlist.wtf | Server address (text file) | Plain text, no executable content |

Total system impact: **Zero**. All files stay in the WoW folder. No registry
entries, no system modifications, no background processes.

To completely uninstall: delete the WoW folder. Done.


## What Happens When You Play

When you're in-game on our server:

1. **You press a key** → Client sends input to server
2. **Server processes your action** → Custom Lua scripts run (on server)
3. **Server sends results** → Standard WoW protocol packets
4. **Client displays results** → You see monsters spawn, loot drop, etc.
5. **Server sends UI data** → AIO renders custom interface elements

At no point does server code run on your machine. At no point does your
client access files outside its directory. The entire interaction is:
input → network → display.


## Questions and Concerns

### "Why should I trust a random server's addon?"

AIO is open-source and widely used across the private server community.
The code is auditable: https://github.com/Rochet2/AIO

More importantly, even if you don't audit the code, WoW's addon API
physically cannot access your system. Blizzard designed it this way
to prevent cheating - the same restrictions protect you from malicious
addons.

### "What data does the server see?"

The server sees:
- Your IP address (like any internet service)
- Your in-game actions (movement, chat, combat)
- Your account credentials (which you create specifically for this server)

The server cannot see:
- Files on your computer
- Other running programs
- Your real identity (unless you share it)
- Anything outside the game session

### "Can I use my retail WoW account?"

No. Private servers have completely separate account systems. Your retail
account credentials will not work and should never be entered. Create a
new account specifically for this server.

---

*Last updated: 2026-04*

*See also: docs/installation.md (for server operators)*

Claude is my computer operator. I mostly do the design work. 
