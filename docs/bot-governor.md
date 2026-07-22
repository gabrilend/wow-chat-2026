# Bot Population Governor — Datapath

*Issue: `issues/151-bot-population-governor.md` · Script:
`scripts/bot-governor` · Knobs: `config/bot-governor.conf`*

The governor is a feedback loop between the host machine's hardware meters
and the number of AI bots logged into the world. More bots when the machine
is quiet, fewer when it runs hot. It lives entirely outside the game server
process and steers it through two narrow channels: the server's SOAP console
endpoint on loopback, and the module's own config file.

## The Loop

```
 /proc/stat ─┐
 /proc/meminfo ├─► meters (cpu / memory / load, % of capacity)
 /proc/loadavg ┘        │
                        ▼
              ┌─── decide (every poll cycle) ───┐
              │  any meter ≥ hot?   → shed      │
              │  all meters < cool  → cool      │
              │   (streak long enough → grow)   │
              │  in between         → hold      │
              └────────────────────────────────┘
                   │ shed                │ grow
                   ▼                     ▼
        pin band lower          pin band higher
        + kick chosen bots      + nudge the module
                   │                     │
                   └────────┬────────────┘
                            ▼
       playerbots.conf  (MinRandomBots = MaxRandomBots = target)
       SOAP 127.0.0.1:7878  ("playerbots rndbot reload", ".kick <name>")
                            │
                            ▼
              worldserver — module converges on target
```

## Why Two Levers

The playerbot module only ever logs bots **in** when below its target; there
is no code path that logs excess bots out when the target drops. Each bot
carries a personal "welcome timer" rolled at login (two hours to fourteen
days) and leaves only when it expires. So the governor:

1. **Pins the band** — writes the module's floor and ceiling to one single
   value and asks it to reload. The module caches its chosen target for up
   to two hours, but re-rolls immediately when the cached value falls
   outside the configured band — and a one-value band makes that re-roll
   deterministic. This closes the door: nothing removed will be replaced.
2. **Kicks the excess** — logs chosen bots out *now* using the server's own
   kick command over SOAP. Which ones get chosen is the logout-method radio
   in the config (idle-looking first, random, newest first — or `drain`,
   which skips kicking entirely and accepts the slow natural decay).

Growth needs no second lever: raising the pinned band is exactly the module's
native "log more bots in" path, at roughly sixty logins per module tick.

## Escalation Shape

Shedding escalates: the first hot cycle removes a small step of bots, and
each consecutive hot cycle doubles the count up to a cap. Any cycle that is
not hot resets the escalation. Growth is the mirror with a longer fuse: only
a sustained streak of fully-cool cycles raises the target one step. The gap
between the hot and cool thresholds is deliberate hysteresis — inside it the
governor holds still.

## The Credential Path

The SOAP endpoint authenticates with HTTP Basic against a real game account
holding administrator security. `bot-governor setup` mints that account
itself: it computes the SRP6 salt/verifier pair the login database stores
(SHA1 plus 256-bit modular arithmetic, done with `sha1sum` and `bc`), upserts
the account rows over the project MySQL socket, and records the credentials
in `scripts/credentials` under the `soap_user` / `soap_pass` keys. The
listener itself is enabled by config patch C021 (loopback only) and spawns
at worldserver boot — the first activation costs one restart.

## What It Reads, What It Writes

| direction | thing | purpose |
|---|---|---|
| reads | `/proc/stat`, `/proc/meminfo`, `/proc/loadavg` | hardware meters |
| reads | `config/bot-governor.conf` | all knobs |
| reads | `scripts/credentials` | MySQL + SOAP credentials |
| reads | installed `worldserver.conf` | SOAP address/port |
| reads | installed `playerbots.conf` | bot account prefix, current band |
| reads | characters + auth databases | who is online, who is a bot, who is grouped/where |
| writes | installed `playerbots.conf` | the pinned band |
| writes | SOAP loopback | reload / kick / announce commands |
| writes | `tmp/governor-<profile>/governor.log` | decision log (RAM-backed) |

On shutdown the governor restores the configured floor/ceiling band and
hands control back to the module (unless the `persist-shrunken-band`
checkbox says otherwise).
