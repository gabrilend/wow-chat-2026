# 1008b - What the Client Saw Is Written Down

## Status
- Created: 2026-10-26
- Parent: Issue 1008 (journals-of-what-each-player-saw)
- Phase: 10
- **Blocked by:** 1008a
- **Blocks:** 1008d

## Overview

The world server writes, into each player's journal, every line of text
it sends to that player's game client. Recording happens where the
server hands a packet to one player's connection, so a line is recorded
exactly for the players whose clients received it: the people in range of
a /say, the members of a channel, the target of a whisper, and the
speaker themselves (the server echoes their own line back to them).

## Current Behavior

Nothing is recorded.

## Intended Behavior

### Where

`WorldSession::SendPacket` (`source-beta/src/server/game/Server/WorldSession.cpp`)
is the one door every packet to one client goes through. A B-patch adds a
check there: if the packet's opcode is one of the text kinds below, and
the session has a real client (not a playerbot) and its account has a
journal key, a copy of the text is handed to the journal writer.

| Opcode | Kind written | What it carries |
|---|---|---|
| `SMSG_MESSAGECHAT` | the chat type: say, yell, whisper, party, guild, channel, system, monster say, emote, ... | all chat, and server system lines |
| `SMSG_GM_MESSAGECHAT` | as above | chat from a game master |
| `SMSG_NOTIFICATION` | notification | the yellow text at the top of the screen |
| `SMSG_CHAT_SERVER_MESSAGE` | server | shutdown and restart warnings |
| `SMSG_MOTD` | motd | message of the day at login |
| `SMSG_AREA_TRIGGER_MESSAGE` | area | area messages |
| `SMSG_RAID_INSTANCE_MESSAGE` | instance | raid lockout warnings |
| `SMSG_DEFENSE_MESSAGE` | defense | "X is under attack" |
| `SMSG_GOSSIP_MESSAGE` | gossip | the options of a conversation menu |

The text is read from a copy of the packet (its layout per opcode is
written as comments beside the reader), never by changing what is sent.

### Off the world's thread

`SendPacket` runs on the world's thread, which must not wait for disk or
cryptography. The check only copies the text, a time and the account id
into a queue (memory set aside up front, a ring of fixed slots). A
journal writer thread empties the queue: locks each line with that
session's stream key (1008a) and appends it to the open file. A full
queue drops lines and counts the drops; the count is written into the
journal as a line of its own when there is room again, so a gap is
never silent.

### Files

`journals/<account id>/<login time>-<session number>.journal` on the
realm's own machine (157g: one machine per realm). Opened at login (the stream key is made then, locked to
the account's public key, and kept only in memory), closed with the
final tag at logout or server shutdown.

Beside each closed file, `<same name>.fingerprint`: the BLAKE2b hash of
the locked file. Anyone can check a file was not changed without being
able to read it; the fingerprints of a player's files are listed in the
rmail reply (1008d).

### Never written

- Anything for an account without a journal key.
- Anything the player sends to the server (their own typing reaches
  their journal only as the server's echo of it). A `.account password`
  command is therefore never in a journal; a test checks this.

## Suggested Implementation Steps

1. B-patch: the opcode check in `SendPacket`, the queue, the writer
   thread (started and stopped with the world), the per-session stream
   key at login and the final tag at logout.
2. Per opcode, a reader for its text, with the packet layout as a
   comment.
3. Test with the cc-test profile: two characters in range, one says a
   line; both journals hold it; a third out of range does not; the
   opener (1008e) reads them.
4. Measure: lines per second the writer keeps up with, on a busy test
   (`scripts/measure-journal-writer`, the owner runs it).

## Open Questions

1. ~~Which kinds~~. Answered 2026-10-28: "chatlog, not combat related
   text or anything like that." A journal is what the chat window
   showed: `SMSG_MESSAGECHAT` and `SMSG_GM_MESSAGECHAT` (every chat type
   the chat window prints: say, yell, emote, whisper, party, raid, guild,
   officer, channels, system, creatures' speech), `SMSG_MOTD`,
   `SMSG_CHAT_SERVER_MESSAGE` (restart warnings print in chat) and
   `SMSG_DEFENSE_MESSAGE` ("under attack" prints in the defence
   channel). Left out: `SMSG_NOTIFICATION` (screen-centre text, not the
   chat window), area and raid-lockout messages, conversation menus,
   quest text, mail, and everything about combat. The table above is to
   be cut to this when 1008b is built.
2. ~~Addon messages~~. Left out: an addon's message (`CHAT_MSG_ADDON`) is
   never printed in the chat window, so it is not in the chat log.

## Related
- `issues/1008a-a-lock-made-from-the-password.md`
- `issues/1008-journals-of-what-each-player-saw.md`
