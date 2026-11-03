# 1008a - A Lock Made From the Password

## Status
- Created: 2026-10-26
- Parent: Issue 1008 (journals-of-what-each-player-saw)
- Phase: 10
- **Blocks:** 1008b, 1008c, 1008e

## Overview

The key pair behind every journal, made from the player's password at the
two moments the server sees it, and the one file format every part of
1008 reads and writes. The same library (libsodium) is used in the server
(C++), in the project's tools (LuaJIT through FFI) and in the browser
(libsodium.js), so a journal locked by one opens in the others.

## Current Behavior

Built so far: the Lua side and its test.

- `scripts/lib/journal-seal.lua` (see `journal-seal.info.md` beside it):
  makes a key pair from a password, writes a journal file (header, then
  locked lines), opens one with a password. Loaded from LuaJIT; finds
  libsodium on the system (`libsodium.so.26` here).
- `scripts/test-journal-seal`: makes a key from a password, writes a
  three-line journal, opens it with the password in another case (the
  game uppercases passwords), and checks that the wrong password, a
  changed byte, a removed line and a cut-off end are each refused with
  an error that says which.

Not built: the server side (the table, the C++ patch at account creation
and password change).

## Intended Behavior

### The key

| Step | Input | Output |
|---|---|---|
| uppercase | password as typed (string) | password as the game stores it (Latin letters uppercased, like `Utf8ToUpperOnlyLatin`) |
| stretch | uppercased password, salt (16 random bytes), Argon2id with ops limit and memory limit | seed (32 bytes) |
| key pair | seed | public key (32 bytes), secret key (32 bytes); `crypto_box_seed_keypair` |

Ops and memory limits: libsodium's "interactive" pair (2 passes, 64 MiB),
stored with each key so they can be changed later without breaking old
journals. **The stretch is not protection** (the owner, 2026-10-26: "this
should not be considered a form of security, for they can always just
apply more compute"). It is how libsodium makes a 32-byte seed from a
password; the light settings are chosen to spare the server's memory
when accounts are made. The password alone protects a journal.

### The table, `acore_auth.account_journal_key`

| Column | Type | Meaning |
|---|---|---|
| `account_id` | INT UNSIGNED, primary key | `acore_auth.account.id` |
| `salt` | BINARY(16) | the stretch's salt |
| `ops_limit` | INT UNSIGNED | Argon2id passes |
| `mem_limit` | BIGINT UNSIGNED | Argon2id memory, bytes |
| `public_key` | BINARY(32) | the lock |
| `made_at` | TIMESTAMP | when (a password change replaces the row) |

`acore_auth` is shared by every realm, so one key serves the player in
every realm.

### The journal file

One file per login session per realm. All numbers little-endian.

| Part | Size | Contents |
|---|---|---|
| magic | 8 bytes | `GSJRNL01` |
| account id | 4 bytes, unsigned | whose journal |
| salt | 16 bytes | the key's salt, so the opener needs no database |
| ops limit | 4 bytes, unsigned | |
| mem limit | 8 bytes, unsigned | |
| sealed day key | 80 bytes | a random 32-byte stream key, locked to the public key (`crypto_box_seal`, 48 bytes overhead) |
| stream header | 24 bytes | `crypto_secretstream_xchacha20poly1305` header |
| lines | each: 4-byte length, then that many locked bytes | one locked record per line of text; the last carries the "final" tag |

A random stream key per file, locked once to the public key, means each
line costs one fast symmetric step, not a public-key step. The stream's
authentication refuses a changed, reordered or removed line, and the
"final" tag tells a file that ended properly from one cut short (a crash
leaves no final tag; the opener reads what is there and says the file
was cut short).

Each record's plain text: `<unix time>\t<kind>\t<sender>\t<text>`, where
kind names where the line came from (1008b's table).

## Suggested Implementation Steps

1. ~~The Lua library and its test~~ (built: see Current Behavior).
2. SQL patch (189d's style) creating `account_journal_key` in
   `acore_auth`.
3. B-patch: libsodium in the server's build (CMake finds `sodium`), and
   in `AccountMgr::CreateAccount` and `AccountMgr::ChangePassword`, after
   the SRP verifier is made, the key row is made from the same uppercased
   password. The password string is wiped (`sodium_memzero`) after.
4. No key for hidden accounts (the buddies' companion and stand-in
   accounts, playerbots' random bots, 157j): their passwords are random
   and nobody reads their journals, so the stretch is skipped for them.
5. A test that a key made by the server opens a journal written by the
   Lua library, and the other way round (both from one password and
   salt): the formats cannot drift apart.

## Open Questions

1. ~~Argon2id cost~~. Answered 2026-10-26: the stretch is not counted as
   protection, so the light "interactive" settings are used.
2. ~~Accented letters in passwords~~. Answered 2026-10-28: "it's just
   bits at the end of the day." And the question rested on a misreading:
   the game's uppercasing (`Utf8ToUpperOnlyLatin`, Util.cpp) changes only
   a-z (`wcharToUpperOnlyLatin` uppercases only when
   `isBasicLatinCharacter`, which is a-z and A-Z) and leaves every other
   character as typed. The Lua library now does exactly that, and refuses
   only text that is not valid UTF-8, which the game refuses too. Tested:
   é stays é, É is a different password, a Cyrillic letter is kept.

## Related
- `issues/1008-journals-of-what-each-player-saw.md`
- `source-beta/src/server/game/Accounts/AccountMgr.cpp`
- `issues/completed/189d-sql-as-patches.md`
