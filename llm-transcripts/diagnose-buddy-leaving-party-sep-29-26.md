# Conversation Summary: agent-a79e4405b8159b783

Generated on: 2026-09-29 13:26:17
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Diagnose (do NOT edit any files, do NOT compile, do NOT start/stop servers) why
a "buddy" bot leaves the player's party almost instantly after joining, and why
it isn't auto-grouped with its owner at all.

Project: /mnt/mtwo/games/azeroth-core/wow-chat-2026 (WoW 3.3.5a AzerothCore
private server, profile "basic", active realm). Buddies are playerbots that
belong to the player: the project's own module is at modules/mod-buddies/ (C++;
copied into the build by patch B036), built on mod-playerbots
(source-beta/modules/mod-playerbots/). Relevant pieces: patches/B037* (a
playerbots switch to not invite alts at login; basic turns it off with config
patch C030), config C029 (AiPlayerbot.KeepAltsInGroup = 1), patches/B038,
src/lua-basic/sargobras.lua (Lua that creates buddies at character creation /
Sargobras menu). Issues describing intent: issues/617*.md (617a*, 617b, 617c*,
etc. — grep for "group", "party", "invite"). Installed config:
installed-files-basic/etc/worldserver.conf and
installed-files-basic/etc/modules/*.conf. Logs of the most recent run:
/tmp/wow-chat-2/logs-basic/ (Server.log, Errors.log, Playerbots.log). MySQL:
host 127.0.0.1 port 3307 user ritz password menardi, client at
mysql/installed-files/bin/mysql (needs
LD_LIBRARY_PATH=mysql/installed-files/lib); databases acore_characters_basic,
acore_playerbots_basic, acore_world_basic, acore_auth. Tables of interest:
buddy_roster (characters db) and whatever mod-buddies defines.

What the user reported: they created a human character; character creation let
them pick buddies; the buddy did not enter a party with them automatically
(intended: buddies auto-join their owner's party). They invited her manually,
she joined, then almost immediately left.

Find: (1) where the auto-grouping is supposed to happen (or whether it was ever
built), and why it didn't; (2) the mechanism that makes the bot leave the group
right after joining — look at playerbots' leave-group logic (e.g.
LeaveGroupAction / "leave far away" / master checks / random-bot vs alt-bot
handling / KeepAltsInGroup), and at mod-buddies' own group code and B037's
changes. Check logs and the DB state (e.g. playerbots tables for the bot,
account type, whether the bot's "master" is set) for evidence. Give a concrete
root cause with file:line references, and a proposed fix described precisely
(which file, what change), noting whether it needs a recompile (C++) or only
config/Lua/SQL. Keep the final report under 500 words, plain language, and say
what you verified versus what you infer.

--------------------------------------------------------------------------------

### User Request 2

[Request interrupted by user]

--------------------------------------------------------------------------------

