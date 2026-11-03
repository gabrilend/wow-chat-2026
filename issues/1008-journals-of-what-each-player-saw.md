# 1008 - Journals of What Each Player Saw

## Status
- Created: 2026-10-26
- Phase: 10 (rmail and the world outside the client)
- **Builds on:** 1001 (rmail addresses), 1003 (rmail account creation),
  157g (the Linode machines; each realm's journals are kept on its own)

## Origin

The owner, 2026-10-26:

> I want to hash chatlogs to the journals of those who saw them, keyed only
> with the user's password. We don't store a copy of their password in
> unencrypted text, and we don't have to key it to open. Only they do, the
> people who observed it pass directly through their chatlogs in-client.
> Any text message we send, we also possess as text directory contents,
> hashed to the user of course. And, if the user creates an rmail request,
> they can download it. We show them exactly how to do this in the same
> section where we tell them how to connect. They will have seen it if they
> can log in.

As understood: every line of text that reaches a player's game client
(chat they were in range of or in the channel of, whispers, system
messages, anything the server says to them) is written into that player's
journal on the server, locked so that only that player's password opens
it. The server keeps the locked journals but cannot read them. A player
asks for theirs by rmail and opens it on their own computer.

"Hash" in the owner's words is taken as **lock** (encrypt): a hash cannot
be turned back into the text, and the player wants to read their journal.
Hashes appear too, as fingerprints that prove a journal was not changed
(1008b).

## The one technical fact the design turns on

The game's login never shows the server the password. The client and the
authserver run SRP6: the server stores a salt and a "verifier" computed
from the password (`acore_auth.account`, columns `salt`, `verifier`), and
at login the client proves it knows the password without sending it.

The server sees a password in plain text at exactly three moments:

| Moment | Where in the server |
|---|---|
| account creation (console `.account create`, SOAP, and 1003's rmail account creation) | `AccountMgr::CreateAccount`, `source-beta/src/server/game/Accounts/AccountMgr.cpp` |
| password change (in game: `.account password old new new`) | `AccountMgr::ChangePassword`, same file |
| checking a password typed at the console | `AccountMgr::CheckPassword` (not used here) |

So the lock is made at creation and at each password change, and
nowhere else. Before this, the password is uppercased by the game
(`Utf8ToUpperOnlyLatin`), which is why WoW passwords ignore case; the
journal key uses the same uppercased password, so it opens with whatever
case the player types.

## How the lock works (libsodium's public-key "sealed box")

1. At creation or password change, with the password in hand: pick 16
   random bytes (the salt). Turn password + salt into 32 bytes, the seed,
   with Argon2id (a function made to take memory and time). From the seed make a key pair: a
   public key (32 bytes) and a secret key (32 bytes).
2. Keep only the salt, the stretching settings and the public key, in a
   new table `acore_auth.account_journal_key`. Forget the password, the
   seed and the secret key.
3. Anyone holding the public key can lock text for that player; only the
   secret key unlocks it, and the secret key is remade only from the
   password. The server can write journals it cannot read.
4. The player's opener (1008e) asks for the password, reads the salt from
   the journal file's own header, remakes the secret key, and unlocks.

**What protects a journal is the password, and only the password.**
Someone holding a journal file (or the stored public key) can guess
passwords offline as fast as their computers allow. The slow stretching
is not counted as protection (the owner, 2026-10-26: "this should not be
considered a form of security, for they can always just apply more
compute"): more computers undo it. It is there because a password has to
be turned into a 32-byte seed somehow, and libsodium's way of doing that
is Argon2id; its settings are the light "interactive" pair, chosen for
the server's memory, not for strength. A journal is as safe as its
password is hard to guess, and 1008f says so to players in those words.

Nothing new is exposed by keeping the public key: someone who stole the
database could already test password guesses against the SRP verifier.

## Sub-issues

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 1008a | a-lock-made-from-the-password | None | The key pair made at account creation and password change; the `account_journal_key` table; the shared lock/unlock library |
| 1008b | what-the-client-saw-is-written-down | 1008a | Every text packet sent to a player's client is locked into their journal, line by line, by a writer thread off the world's thread |
| 1008c | rmail-texts-in-the-same-journal | 1008a | Text sent to a player by rmail (1004's bridge, 1003's replies, narrator) is kept, locked, in the same journal folder |
| 1008d | asking-for-your-journal-by-rmail | 1008b, 1001 | An rmail request to `wow.ritzmenardi.com/journal` returns that account's locked journal files |
| 1008e | opening-a-journal-at-home | 1008a | The opener: a command-line tool, and a page on the website that unlocks in the browser without sending the password anywhere |
| 1008f | how-to-connect-and-read-your-journal | 157g, 1008d, 1008e | One section on the owner's website: how to connect, and how to fetch and open your journal |
| 1008g | a-box-for-every-realm | None | Each realm on the connection page as a game box: cover art from off-brand tokens, the back in a kid's voice |

**Why split:** the lock (a), the recording inside the world server (b),
rmail's copies (c), fetching (d), opening (e) and the public page (f) are
built and tested apart, in different languages and places (C++ patch,
Lua tools, rmail scripts, a web page), and only (a) must come first.

**Order:** `1008a → 1008b, 1008c, 1008e (parallel) → 1008d → 1008f`

## Current Behavior

- Chat is not kept anywhere by the server (the server's chat log, if
  switched on in `worldserver.conf`, writes plain text; it is off).
- 1008a's shared library is built: `scripts/lib/journal-seal.lua`
  (LuaJIT, libsodium through FFI), tested by `scripts/test-journal-seal`.
  Nothing in the server uses it yet.

## Intended Behavior

- Every account made or re-passworded after this lands has a journal key.
  Accounts without one have nothing recorded. No text is ever written
  unlocked. (There are two such accounts today, the owner's and one
  other; both get their passwords reset when this lands, owner,
  2026-10-26. A login message for keyless accounts is therefore not
  built.)
- **Guest accounts keep no journal** (owner, 2026-10-26: "yes, no
  journal, but also they can be kicked off whenever"). Their passwords
  are public, so a journal for one would open for anyone. No key is made
  for them even when their password is set, and they are the first to be
  disconnected when a realm restarts or fills (157h).
- On each realm's machine (157g), `journals/<account id>/` holds that
  player's locked journal files for that realm, one per login session.
- The player fetches their files by rmail and opens them at home.
- Each profile's worldserver writes only its own realm's folder, so all
  realms running at once (157g) never write the same file.

## Suggested Implementation Steps

1. 1008a, then the sub-issues in the order above.
2. `docs/datapaths/journals.md`: a line of chat from the speaker's client
   to the observer's journal to the observer's screen at home; added to
   `docs/table-of-contents.md`.

## Open Questions

1. ~~Accounts made before this~~. Answered 2026-10-26: there are two;
   their passwords are reset when this lands.
2. ~~A changed password~~. Answered 2026-10-28: "yeah. they can request
   another one maybe if they want a new password?" A password change
   makes a new key, and journals from then on use it; old journals keep
   the old lock, and the opener takes several passwords. As understood,
   "request another one": a player who wants their old journals under
   the new password opens them at home with the old one and keeps them
   that way; the server cannot re-lock what it cannot read.
3. ~~Bots~~. Settled by 157j (2026-10-26): bot accounts are hidden
   accounts, made with a random password, and get no key; nothing is
   recorded for them.
4. **How long journals are kept** on the host, and whether a player can
   ask for theirs to be deleted (by the same rmail address).
5. **Telling players.** Players should know their chat is being written
   into other players' journals (locked to those players). The connect
   section (1008f) says it; should the server also say it at first login?
6. ~~The guest accounts~~. Answered 2026-10-26: no journal, and they
   can be kicked off whenever.

## Related
- `issues/1003-rmail-account-creation.md`: accounts made through rmail
  get their journal key at the same moment
- `issues/1004-rmail-ingame-bridge.md`, `issues/1001-rmail-dns-style-addresses.md`
- `issues/157g-linode-machines-one-per-realm.md`
- `issues/158-player-machine-safety-before-public-release.md`
