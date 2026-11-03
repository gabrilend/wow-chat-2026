# journal-seal.lua

Locks a player's journal so only their password opens it, and opens it
again (issue 1008a). LuaJIT, libsodium through the FFI. Load with
`local Seal = dofile(DIR .. "/scripts/lib/journal-seal.lua")`.
The file format is a table at the top of the source and in issue 1008a.

## Functions

| Function | Takes | Gives |
|---|---|---|
| `Seal.make_key(password, salt, ops, mem)` | password (string, as typed; ASCII only, uppercased like the game does); salt (16-byte string, or nil for a new random one); ops, mem (numbers, Argon2id limits; nil for "interactive": 2 passes, 64 MiB) | a key table: `salt` (string 16), `ops` (number), `mem` (number), `public_key` (string 32), `secret_key` (string 32) |
| `Seal.writer(path, account_id, key)` | path (string); account id (number); key (table with `salt`, `ops`, `mem`, `public_key`: no secret needed) | a writer: `:line(record)` appends one locked line, `:close()` writes the final mark |
| `Seal.open(path, passwords)` | path (string); one password (string) or several (list of strings) | `account_id` (number), `lines` (list of record strings), `finished` (boolean: false when cut short). Raises an error naming the cause when no password fits, the file is not a journal, or a line was changed, removed, reordered or added after the end |
| `Seal.record(time, kind, sender, text)` | unix time (number), kind, sender, text (strings) | one record string, tabs and newlines inside fields turned to spaces |
| `Seal.parse_record(s)` | a record string | table: `time` (number), `kind`, `sender`, `text` (strings) |
| `Seal.fingerprint(path)` | path (string) | BLAKE2b of the whole file, 64 hex digits (string) |

## Values

`Seal.MAGIC` (string, `GSJRNL01`), `Seal.HEADER_BYTES` (number, 144),
`Seal.OPS_INTERACTIVE`, `Seal.MEM_INTERACTIVE` (numbers, from libsodium).

## Used by

`scripts/open-journal` (1008e), `scripts/test-journal-seal`; later the
rmail services (1008c, 1008d). The world server writes the same format
from C++ (1008b).
