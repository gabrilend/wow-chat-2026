# 157j - The Login Database Behind an Instruction Door

## Status
- Created: 2026-10-26
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1 (Foundation — the server runs)
- **Blocks:** 157g

## Origin

The owner, 2026-10-26:

> each machine should have any database it contacts located on it's own
> machine, to increase the data processing speed and improve reliability.
>
> the auth database however can exist on it's own device, hardened
> against any outside connection, making it difficult to hack. We must
> also use an instruction oriented transmission format.

## Overview

`acore_auth` holds every account, its password verifier, its journal key
(1008a), bans, and the realm list. Every realm and the login server need
it, so it cannot sit on any one of their machines. It gets a device of
its own that takes no connection from the internet, and that answers its
neighbours only through a door that accepts a fixed list of instructions,
never SQL text. A machine that is broken into can ask only what the list
allows: it cannot read every verifier, drop a table, or run a query
nobody wrote.

## Current Behavior

Every server talks to `acore_auth` as a full MySQL client, with a user
and password that may run any SQL. Measured 2026-10-26 in `source-beta`:

| Who | How it reaches the login database | Count |
|---|---|---|
| core (worldserver and authserver) | numbered prepared statements, `LOGIN_*` in `src/server/database/Database/Implementation/LoginDatabase.cpp` | 110 |
| core | SQL text written inline (`LoginDatabase.Query("...")`, `DirectExecute("...")`), e.g. the realm list's online flag in `apps/worldserver/Main.cpp` | 22 |
| mod-playerbots | SQL text written inline (bot accounts are made in `acore_auth`) | 7 |
| our Lua (through ALE's `AuthDBQuery`/`AuthDBExecute`) | SQL text | `src/lua-vanilla/redirect-probe.lua`, `src/lua-basic/death-knight-souls.lua` |

## Intended Behavior

### The device

- Runs MySQL with `acore_auth`, listening on its own 127.0.0.1 only, and
  the instruction door, listening on Linode's private network only.
- Its firewall accepts the door's port from the listed machines' private
  addresses (the login machine and each realm machine, from the roles
  file) and nothing else. No ssh from the internet (157i open question
  1 decides how it is administered).
- Built by 157i like the others: only MySQL, the door, runit.

### The instruction format

The core already speaks in numbered instructions: each `LOGIN_*`
statement is a number with typed parameters. The door's format is those
numbers:

| Field | Type | Meaning |
|---|---|---|
| length | uint32 | bytes that follow |
| instruction | uint16 | a `LOGIN_*` number, or one of ours (below) |
| sender realm | uint16 | which realm machine asks (checked against the connection's address) |
| parameter count | uint8 | |
| parameters | each: type tag (uint8: int, uint, float, string, binary), then the value | |

The reply: a status byte, a row count, then the rows as typed values.

The door holds one table, instruction number → the SQL it runs and which
machines may ask it (`config/login-door/instructions.lua`, generated
from `LoginDatabase.cpp` by a tool, so the two never drift apart). An
instruction not in the table, from a machine not allowed it, or with
parameters of the wrong types is refused and logged with the asker's
address.

The 22 + 7 inline SQL lines and our Lua's raw SQL become instructions
of their own (numbered from 1000, named for what they do, e.g. "mark
this realm online"), through B-patches that turn each inline line into
a numbered statement, and through Lua helpers that send instructions
instead of SQL.

### Accounts a realm may make

The buddy module makes its companion and stand-in accounts itself, in
the realm, when they are first needed
(`patches/B036-mod-buddies/mod-buddies/src/buddies_clan.cpp`, "Ensure
companion account"): the name is worked out from the owner character's
number, the password is 8 random bytes nobody is told, and nobody ever
logs in with it (the realm logs the bot in itself). Playerbots' random
bot accounts are made the same way.

So a realm may send one account-making instruction, "make hidden
account", and no other: the door checks the name has one of the hidden
accounts' forms (companion, stand-in, random bot), makes the random
password itself (the realm never sees it), and makes no journal key for
it (1008a: nobody reads a bot's journal). A realm cannot make an account
with a name a person would use, change a password, or touch an account it
did not make.

### In the servers

A B-patch gives `LoginDatabase` a second kind of connection: instead of a
MySQL session it sends the instruction and parameters to the door and
reads the rows back, and the rest of the server cannot tell the
difference. Chosen in `worldserver.conf` / `authserver.conf` by the
connection string's form (`door:<address>:<port>` instead of a MySQL
host).

## Suggested Implementation Steps

1. List every place the login database is reached (the table above, by
   a tool, kept up to date by the compile's quick tests).
2. The instruction table generator from `LoginDatabase.cpp`.
3. B-patches: each inline SQL line becomes a numbered statement.
4. The door (a small C++ or Lua program on the device) and its test:
   allowed instructions answer, others are refused and logged.
5. The door connection inside the servers' database layer.
6. Our Lua's two scripts use instructions.
7. Test: a realm machine image (157i) in QEMU logs a character in
   through the door.

## Open Questions

1. ~~Who may make accounts~~. Answered 2026-10-26: bot accounts are
   handled "the same way we handle the buddy-bot accounts" (see
   Intended Behavior, "Accounts a realm may make").
2. ~~Speed~~. The owner, 2026-10-28: "um... Not sure how to answer
   this." Decided here, to be measured: one round trip per lookup, no
   copies kept by the realms. A copy would be a second place an
   account's state lives (a ban or a password change would wait for it to
   expire), and the door's whole point is that the login database is the
   only place. A lookup over a private network inside one Linode data
   centre is a fraction of a millisecond plus the database's own time;
   the door's test measures it (`scripts/measure-login-door`, lookups per
   second and the slowest one), and only a measured problem reopens
   this.

## Related
- `issues/157k-realms-closed-until-you-log-in.md`: "let in" uses this
  format
- `issues/617a-buddy-roster-and-creation.md`: the companion accounts
- `issues/157g-linode-machines-one-per-realm.md`
- `issues/157i-a-linux-of-only-what-runs.md`
- `issues/1008a-a-lock-made-from-the-password.md`: the journal keys live
  in `acore_auth`
- `issues/136a-unified-realmlist.md`
